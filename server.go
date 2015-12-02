package slashdeploy

import (
	"io"
	"net/http"

	"github.com/gorilla/mux"
)

type ServerConfig struct {
	// Shared secret to verify that slash commands originated from Slack.
	SlackVerificationToken string
}

// Server is an http.Handler that servers the SlashDeploy application.
type Server struct {
	http.Handler
}

// NewServer returns a new Server instance.
func NewServer(config ServerConfig) *Server {
	r := mux.NewRouter()
	s := &Server{Handler: r}

	r.HandleFunc("/", s.Root)

	//r.Handle("/commands")

	//r.Handle("/auth")

	return s
}

func (s *Server) Root(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, "Ok\n")
}
