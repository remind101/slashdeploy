// Package slashtest contains helpers for testing slash commands.
package slashtest

import (
	"sync"

	"github.com/ejholmes/slash"
)

type ResponseRecorder struct {
	mu sync.Mutex // Protects writing to Responses

	Responses []slash.Response
}

func NewRecorder() *ResponseRecorder {
	return &ResponseRecorder{}
}

func (r *ResponseRecorder) Respond(resp slash.Response) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.Responses = append(r.Responses, resp)
	return nil
}
