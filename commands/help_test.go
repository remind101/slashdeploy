package commands

import (
	"testing"

	"github.com/ejholmes/slash"
	"github.com/stretchr/testify/assert"
	"golang.org/x/net/context"
)

func TestHelp(t *testing.T) {
	resp, err := Help.ServeCommand(context.Background(), nil, slash.Command{})
	assert.NoError(t, err)
	assert.Equal(t, helpText, resp.Text)
}
