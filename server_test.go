package slashdeploy

import (
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"

	"golang.org/x/oauth2"
)

func TestServer_SlackAuthCallback(t *testing.T) {
	var called bool

	slack := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		called = true
		assert.Equal(t, "/api/oauth.access", r.URL.Path)

		w.Header().Set("Content-Type", "application/json")
		io.WriteString(w, `{
    "access_token": "xoxp-XXXXXXXX-XXXXXXXX-XXXXX",
    "scope": "incoming-webhook,commands",
    "team_name": "Team Installing Your Hook",
    "incoming_webhook": {
        "url": "https://hooks.slack.com/TXXXXX/BXXXXX/XXXXXXXXXX",
        "channel": "#channel-it-will-post-to",
        "configuration_url": "https://teamname.slack.com/services/BXXXXX"
    }
}`)
	}))
	defer slack.Close()

	s := &Server{
		slackConfig: &oauth2.Config{
			Endpoint: oauth2.Endpoint{
				TokenURL: fmt.Sprintf("%s/api/oauth.access", slack.URL),
			},
		},
	}

	req, _ := http.NewRequest("GET", "?code=1234&state=", nil)
	resp := httptest.NewRecorder()

	s.SlackAuthCallback(resp, req)

	t.Log(resp.Body.String())

	assert.Equal(t, http.StatusTemporaryRedirect, resp.Code)
	assert.True(t, called)
}

func TestServer_SlackAuthCallback_BadClientSecret(t *testing.T) {
	var called bool

	slack := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		called = true
		assert.Equal(t, "/api/oauth.access", r.URL.Path)

		w.Header().Set("Content-Type", "application/json")
		io.WriteString(w, `{
    "ok": false,
    "error": "bad_client_secret"
}`)
	}))
	defer slack.Close()

	s := &Server{
		slackConfig: &oauth2.Config{
			Endpoint: oauth2.Endpoint{
				TokenURL: fmt.Sprintf("%s/api/oauth.access", slack.URL),
			},
		},
	}

	req, _ := http.NewRequest("GET", "?code=1234&state=", nil)
	resp := httptest.NewRecorder()

	s.SlackAuthCallback(resp, req)

	t.Log(resp.Body.String())

	assert.Equal(t, http.StatusBadRequest, resp.Code)
	assert.True(t, called)
}
