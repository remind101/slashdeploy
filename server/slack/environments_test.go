package slack

import (
	"testing"

	"github.com/ejholmes/slash"
	"github.com/ejholmes/slash/slashtest"
	"github.com/ejholmes/slashdeploy"
	"github.com/stretchr/testify/assert"
	"golang.org/x/net/context"
)

func TestEnvironmentsCommand(t *testing.T) {
	d := new(mockClient)
	c := &EnvironmentsCommand{
		client: d,
	}

	ctx := slash.WithParams(context.Background(), map[string]string{
		"repo": "ejholmes/acme-inc",
	})
	rec := slashtest.NewRecorder()
	cmd := slash.Command{}

	d.On("ListEnvironments", "ejholmes/acme-inc").Return([]*slashdeploy.Environment{
		{Name: "production"},
		{Name: "staging"},
	}, nil)

	err := c.ServeCommand(ctx, rec, cmd)
	assert.NoError(t, err)
	assert.Equal(t, `I know about these environments for ejholmes/acme-inc
* production
* staging`, (<-rec.Responses).Text)
}

func TestEnvironmentsCommand_NoEnvironments(t *testing.T) {
	d := new(mockClient)
	c := &EnvironmentsCommand{
		client: d,
	}

	ctx := slash.WithParams(context.Background(), map[string]string{
		"repo": "ejholmes/acme-inc",
	})
	rec := slashtest.NewRecorder()
	cmd := slash.Command{}

	d.On("ListEnvironments", "ejholmes/acme-inc").Return([]*slashdeploy.Environment{}, nil)

	err := c.ServeCommand(ctx, rec, cmd)
	assert.NoError(t, err)
	assert.Equal(t, `No known environments for ejholmes/acme-inc`, (<-rec.Responses).Text)
}
