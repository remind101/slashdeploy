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

// Server is an http.Handler that servers the SlashDeploy application.
type Server struct {
	*SlashDeploy
	http.Handler
}

// NewServer returns a new Server instance.
func NewServer(sd *SlashDeploy, commands slash.Handler) *Server {
	r := mux.NewRouter()
	s := &Server{
		SlashDeploy: sd,
		Handler:     r,
	}

	// Handle root for docs.
	r.HandleFunc("/", s.Root)

	// Where the slash commands are served from.
	r.Handle("/commands", slash.NewServer(commands))

	// Handle slack auth callback.
	r.Handle("/auth/slack/callback", &SlackAuthCallback{Config: s.SlackOAuth})

	// Handle github auth callback
	r.Handle("/auth/github/callback", &GitHubAuthCallback{Config: s.GitHubOAuth, Users: s.Users})

	return s
}

func (s *Server) Root(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, "Ok\n")
}

func (s *Server) SlackAuthCallback(w http.ResponseWriter, r *http.Request) {
	code := r.FormValue("code")

	token, err := s.SlackOAuth.Exchange(oauth2.NoContext, code)
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
