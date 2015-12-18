package slack

import (
	"testing"

	"github.com/ejholmes/slash"
	"github.com/ejholmes/slash/slashtest"
	"github.com/stretchr/testify/assert"
	"golang.org/x/net/context"
)

func TestHelpCommand(t *testing.T) {
	rec := slashtest.NewRecorder()
	err := HelpCommand.ServeCommand(context.Background(), rec, slash.Command{})
	assert.NoError(t, err)
	assert.Equal(t, HelpText, (<-rec.Responses).Text)
}
