package slashdeploy

import (
	"io"
	"net/http"

	"golang.org/x/oauth2"

	"github.com/ejholmes/slash"
	"github.com/gorilla/mux"
)

// Basic OAuth settings for Slack.
var (
	DefaultSlackScopes   = []string{"commands"}
	DefaultSlackEndpoint = oauth2.Endpoint{
		TokenURL: "https://slack.com/api/oauth.access",
	}
)

type ServerConfig struct {
	// Shared secret to verify that slash commands originated from Slack.
	SlackVerificationToken string

	// OAuth settings for Slack.
	SlackClientID, SlackClientSecret string
}

// Server is an http.Handler that servers the SlashDeploy application.
type Server struct {
	slackConfig *oauth2.Config
	http.Handler
}

// NewServer returns a new Server instance.
func NewServer(config ServerConfig) *Server {
	r := mux.NewRouter()
	s := &Server{
		Handler: r,
		slackConfig: &oauth2.Config{
			ClientID:     config.SlackClientID,
			ClientSecret: config.SlackClientSecret,
			Scopes:       DefaultSlackScopes,
			Endpoint:     DefaultSlackEndpoint,
		},
	}

	r.HandleFunc("/", s.Root)
	r.Handle("/commands", slash.NewServer(newCommand(config.SlackVerificationToken)))
	r.HandleFunc("/auth/slack/callback", s.SlackAuthCallback)

	return s
}

func (s *Server) Root(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, "Ok\n")
}

func (s *Server) SlackAuthCallback(w http.ResponseWriter, r *http.Request) {
	code := r.FormValue("code")

	token, err := s.slackConfig.Exchange(oauth2.NoContext, code)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err, ok := token.Extra("error").(string); ok {
		http.Error(w, err, http.StatusBadRequest)
		return
	}

	http.Redirect(w, r, "/", http.StatusTemporaryRedirect)
}
