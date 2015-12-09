package main

import (
	"net/http"

	"github.com/codegangsta/cli"
	"github.com/ejholmes/slash"
	"github.com/ejholmes/slashdeploy"
	"github.com/ejholmes/slashdeploy/auth"
	"github.com/ejholmes/slashdeploy/commands"
	"github.com/ejholmes/slashdeploy/deployments"
	"github.com/ejholmes/slashdeploy/deployments/github"
	"github.com/ejholmes/slashdeploy/users"
	"golang.org/x/oauth2"

	slackoauth "github.com/ejholmes/slashdeploy/pkg/oauth2/slack"
	githuboauth "golang.org/x/oauth2/github"
)

type oauthConfig struct {
	slack  *oauth2.Config
	github *oauth2.Config
}

// service factory
type factory struct {
	deploymentsService *deployments.Service
	usersService       *users.Service
	commands           slash.Handler
	stateEncoder       interface {
		auth.StateEncoder
		auth.StateDecoder
	}
	oauthConfig *oauthConfig
	server      http.Handler
	*cli.Context
}

func newFactory(c *cli.Context) *factory {
	s := &slashdeploy.SlashDeploy{
		Users: slashdeploy.NewMemUsersStore(),
	}

	return &factory{
		Context: c,
		deploymentsService: &deployments.Service{
			BuildDeployer: func(user *slashdeploy.User) deployments.Deployer {
				return github.NewDeployer(user.GitHubToken)
			},
		},
		usersService: &users.Service{
			Users: s.Users,
		},
		stateEncoder: auth.SignedState([]byte(c.String("state.key"))),
		oauthConfig: &oauthConfig{
			slack: &oauth2.Config{
				ClientID:     c.String("slack.client.id"),
				ClientSecret: c.String("slack.client.secret"),
				Scopes:       []string{"commands"},
				Endpoint:     slackoauth.Endpoint,
			},
			github: &oauth2.Config{
				ClientID:     c.String("github.client.id"),
				ClientSecret: c.String("github.client.secret"),
				Scopes:       []string{"repo_deployment"},
				Endpoint:     githuboauth.Endpoint,
			},
		},
	}
}

func (f *factory) Commands() slash.Handler {
	if f.commands == nil {
		f.commands = commands.New(f.String("slack.verification.token"), commands.SubCommands{
			Help:   commands.Help,
			Deploy: f.GitHubAuthenticate(commands.NewDeploy(f.deploymentsService)),
		})
	}
	return f.commands
}

func (f *factory) GitHubAuthenticate(h slash.Handler) slash.Handler {
	return &auth.Authenticator{
		Users:        f.usersService,
		Config:       f.oauthConfig.github,
		StateEncoder: f.stateEncoder,
		Handler:      h,
	}
}

func (f *factory) Server() http.Handler {
	if f.server == nil {
		f.server = slashdeploy.NewServer(slashdeploy.Handlers{
			Commands:           slash.NewServer(f.Commands()),
			SlackAuthCallback:  &auth.SlackAuthCallback{Config: f.oauthConfig.slack},
			GitHubAuthCallback: &auth.GitHubAuthCallback{Config: f.oauthConfig.github, Users: f.usersService, StateDecoder: f.stateEncoder},
		})
	}
	return f.server
}
