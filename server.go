package slashdeploy

import (
	"io"
	"net/http"

	"github.com/gorilla/mux"
)

// Server is an http.Handler that servers the SlashDeploy application.
type Server struct {
	http.Handler
}

type Handlers struct {
	Commands           http.Handler
	SlackAuthCallback  http.Handler
	GitHubAuthCallback http.Handler
}

// NewServer returns a new Server instance.
func NewServer(handlers Handlers) *Server {
	r := mux.NewRouter()
	s := &Server{
		Handler: r,
	}

	// Handle root for docs.
	r.HandleFunc("/", s.Root)

	// Where the slash commands are served from.
	r.Handle("/commands", handlers.Commands)

	// Handle slack auth callback.
	r.Handle("/auth/slack/callback", handlers.SlackAuthCallback)

	// Handle github auth callback
	r.Handle("/auth/github/callback", handlers.GitHubAuthCallback)

	return s
}

func (s *Server) Root(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, "Ok\n")
}
