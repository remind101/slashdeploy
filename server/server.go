package server

import (
	"io"
	"net/http"

	"github.com/ejholmes/slash"
	"github.com/ejholmes/slashdeploy"
	"github.com/ejholmes/slashdeploy/server/auth"
	"github.com/ejholmes/slashdeploy/server/slack"
	"github.com/gorilla/mux"

	"golang.org/x/oauth2"
)

// OAuthConfig contains oauth2 configurations for various providers.
type OAuthConfig struct {
	GitHub *oauth2.Config
	Slack  *oauth2.Config
}

// Config is passed to new server.
type Config struct {
	OAuth *OAuthConfig

	// StateKey is a secret key used to sign the oauth2 state param.
	StateKey []byte

	// Token shared between SlashDeploy and Slack to verify slash commands.
	SlackVerificationToken string
}

// New returns a new http.Handler serving the SlashDeploy application.
func New(c *slashdeploy.Client, config Config) http.Handler {
	r := mux.NewRouter()

	// TODO: Serve frontend.
	r.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, "Ok")
	})

	state := auth.SignedState(config.StateKey)
	githubAuth := func(h slash.Handler) slash.Handler {
		return &auth.Authenticator{
			Users:        c,
			Config:       config.OAuth.GitHub,
			StateEncoder: state,
			Handler:      h,
		}
	}

	// Mount slack commands.
	cmds := slash.NewServer(githubAuth(slack.New(config.SlackVerificationToken, c)))
	r.Handle("/commands", cmds)
	r.Handle("/slack", cmds)

	// Mount oauth callbacks.
	r.Handle("/auth/slack/callback", &auth.SlackAuthCallback{Config: config.OAuth.Slack})
	r.Handle("/auth/github/callback", &auth.GitHubAuthCallback{Config: config.OAuth.GitHub, Users: c.Users, StateDecoder: state})

	return r
}
