package slack

import (
	"testing"

	"github.com/ejholmes/slash"
	"github.com/stretchr/testify/assert"
	"golang.org/x/net/context"
)

func TestHelpCommand(t *testing.T) {
	resp, err := HelpCommand.ServeCommand(context.Background(), nil, slash.Command{})
	assert.NoError(t, err)
	assert.Equal(t, HelpText, resp.Text)
}
