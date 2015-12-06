package commands

import (
	"testing"

	"github.com/ejholmes/slash"
	"github.com/stretchr/testify/assert"
	"golang.org/x/net/context"
)

func Test_CommandNotFound(t *testing.T) {
	c := New("token", SubCommands{})

	_, err := c.ServeCommand(context.Background(), nil, slash.Command{
		Command: "/foo",
	})
	assert.Equal(t, slash.ErrNoHandler, err)
}

func Test_InvalidToken(t *testing.T) {
	c := New("token", SubCommands{})

	_, err := c.ServeCommand(context.Background(), nil, slash.Command{
		Command: "/deploy",
	})
	assert.Equal(t, slash.ErrInvalidToken, err)
}

func Test_Routes(t *testing.T) {
	cmds := SubCommands{
		Help:   new(recordParamsHandler),
		Deploy: new(recordParamsHandler),
	}

	tests := []struct {
		text    string
		handler slash.Handler
		params  map[string]string
	}{
		{"help", cmds.Help, map[string]string{}},
		{"ejholmes/acme-inc", cmds.Deploy, map[string]string{"repo": "ejholmes/acme-inc"}},
		{"ejholmes/acme-inc to staging", cmds.Deploy, map[string]string{"repo": "ejholmes/acme-inc", "environment": "staging"}},
		{"ejholmes/acme-inc@topic-branch", cmds.Deploy, map[string]string{"repo": "ejholmes/acme-inc", "ref": "topic-branch"}},
		{"ejholmes/acme-inc@topic-branch to staging", cmds.Deploy, map[string]string{"repo": "ejholmes/acme-inc", "ref": "topic-branch", "environment": "staging"}},
	}

	for _, tt := range tests {
		h := tt.handler.(*recordParamsHandler)
		h.params = nil // Reset

		c := New("token", cmds)

		c.ServeCommand(context.Background(), nil, slash.Command{
			Token:   "token",
			Command: "/deploy",
			Text:    tt.text,
		})

		assert.Equal(t, tt.params, h.params)
	}
}

type recordParamsHandler struct {
	params map[string]string
}

func (m *recordParamsHandler) ServeCommand(ctx context.Context, r slash.Responder, c slash.Command) (slash.Response, error) {
	m.params = slash.Params(ctx)
	return slash.NoResponse, nil
}
