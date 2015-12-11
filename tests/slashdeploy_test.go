package slashdeploy_test

import (
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"regexp"
	"strings"
	"testing"

	"golang.org/x/oauth2"

	"github.com/ejholmes/slashdeploy"
	"github.com/ejholmes/slashdeploy/server"
	"github.com/jmoiron/sqlx"
	_ "github.com/mattn/go-sqlite3"
	"github.com/stretchr/testify/assert"
)

var (
	stateKey   = []byte("state_key")
	slackToken = "slack_token"
)

func TestRoot(t *testing.T) {
	s := newServer(t)
	defer s.Close()

	resp := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/", nil)

	s.ServeHTTP(resp, req)
	assert.Equal(t, http.StatusOK, resp.Code)
}

func TestAuthSlackCallback(t *testing.T) {
	s := newServer(t)
	defer s.Close()

	resp := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/auth/slack/callback", nil)

	s.ServeHTTP(resp, req)
	assert.Equal(t, http.StatusTemporaryRedirect, resp.Code)
	assert.Equal(t, "/", resp.Header().Get("Location"))
}

var authURLRegex = regexp.MustCompile(`<(.*?)\|(.*?)>`) // Heh

func TestDeployCommand(t *testing.T) {
	s := newServer(t)
	defer s.Close()

	// Attempt to perform a deployment.
	resp := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/commands", strings.NewReader(`command=/deploy&text=remind101/acme-inc&token=slack_token`))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	s.ServeHTTP(resp, req)

	// We're a new user, so we get a response to authenticate. Click on the
	// provided link to oauth with GitHub.
	matches := authURLRegex.FindStringSubmatch(resp.Body.String())
	authURL := matches[1]
	req, _ = http.NewRequest("GET", authURL, nil)
	res, err := http.DefaultTransport.RoundTrip(req) // Use transport to avoid auto redirect.
	assert.NoError(t, err)

	// GitHub redirects us back to SlashDeploy.
	resp = httptest.NewRecorder()
	req, _ = http.NewRequest("GET", res.Header.Get("Location"), nil)
	s.ServeHTTP(resp, req)
	assert.NoError(t, err)
	assert.Equal(t, http.StatusOK, resp.Code)

	// Try deploying again, now that we're authenticated.
	resp = httptest.NewRecorder()
	req, _ = http.NewRequest("POST", "/commands", strings.NewReader(`command=/deploy&text=remind101/acme-inc&token=slack_token`))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	s.ServeHTTP(resp, req)
	assert.NoError(t, err)
	assert.Equal(t, http.StatusOK, resp.Code)
}

func newClient(t testing.TB) *slashdeploy.Client {
	db := sqlx.MustConnect("sqlite3", ":memory:")
	err := slashdeploy.MigrateUp(db, "sqlite3")
	if err != nil {
		t.Fatal(err)
	}

	c := slashdeploy.New(db)
	c.BuildDeployer = func(*slashdeploy.User) slashdeploy.Deployer {
		return slashdeploy.NullDeployer
	}
	return c
}

// Server wraps a Client server instance in a httptest.Server.
type Server struct {
	*slashdeploy.Client
	http.Handler
	slack  *fakeOAuthServer
	github *fakeOAuthServer
}

func newServer(t testing.TB) *Server {
	c := newClient(t)

	slack := newFakeOAuthServer("/auth/slack/callback")
	github := newFakeOAuthServer("/auth/github/callback")

	return &Server{
		slack:  slack,
		github: github,
		Client: c,
		Handler: server.New(c, server.Config{
			OAuth: &server.OAuthConfig{
				Slack:  slack.Config,
				GitHub: github.Config,
			},
			StateKey:               stateKey,
			SlackVerificationToken: slackToken,
		}),
	}
}

func (s *Server) Close() error {
	s.github.Close()
	s.slack.Close()
	return nil
}

// fakeOAuthServer wraps an oauth2.Config with a fake http server.
type fakeOAuthServer struct {
	*httptest.Server
	*oauth2.Config
}

func newFakeOAuthServer(callback string) *fakeOAuthServer {
	s := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/auth":
			state := r.FormValue("state")
			http.Redirect(w, r, fmt.Sprintf("%s?state=%s", callback, state), http.StatusTemporaryRedirect)
		case "/token":
			w.Header().Set("Content-Type", "application/json")
			io.WriteString(w, `{"access_token":"access_token"}`)
		}
	}))
	return &fakeOAuthServer{
		Server: s,
		Config: &oauth2.Config{
			ClientID:     "client_id",
			ClientSecret: "client_secret",
			Endpoint: oauth2.Endpoint{
				AuthURL:  fmt.Sprintf("%s/auth", s.URL),
				TokenURL: fmt.Sprintf("%s/token", s.URL),
			},
		},
	}
}
