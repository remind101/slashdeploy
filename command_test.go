package slashdeploy

import (
	"testing"

	"github.com/ejholmes/slash"
	"github.com/ejholmes/slash/slashtest"
	"github.com/stretchr/testify/assert"
	"golang.org/x/net/context"
)

func TestCommand_Help(t *testing.T) {
	c := newCommand("token")

	rec := slashtest.NewRecorder()
	cmd := slash.Command{Command: "/deploy", Text: "help", Token: "token"}

	resp, err := c.ServeCommand(context.Background(), rec, cmd)
	assert.NoError(t, err)
	assert.Equal(t, helpText, resp.Text)
}
