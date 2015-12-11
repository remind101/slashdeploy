package slack

import (
	"testing"

	"golang.org/x/net/context"

	"github.com/ejholmes/slash"
	"github.com/ejholmes/slash/slashtest"
	"github.com/ejholmes/slashdeploy"
	"github.com/stretchr/testify/assert"
)

func TestDeployCommand(t *testing.T) {
	d := new(mockClient)
	c := &DeployCommand{
		Commands: &Commands{
			client: d,
		},
	}

	ctx := slash.WithParams(context.Background(), map[string]string{
		"repo":        "ejholmes/acme-inc",
		"environment": "staging",
		"ref":         "topic-branch",
	})
	rec := slashtest.NewRecorder()
	cmd := slash.Command{}

	d.On("CreateDeployment", slashdeploy.DeploymentRequest{
		Owner:       "ejholmes",
		Repository:  "acme-inc",
		Ref:         "topic-branch",
		Environment: "staging",
	}).Return(&slashdeploy.Deployment{}, nil)

	_, err := c.ServeCommand(ctx, rec, cmd)
	assert.NoError(t, err)
}

func TestDeployCommand_InvalidRepo(t *testing.T) {
	d := new(mockClient)
	c := &DeployCommand{
		Commands: &Commands{
			client: d,
		},
	}

	ctx := slash.WithParams(context.Background(), map[string]string{})
	rec := slashtest.NewRecorder()
	cmd := slash.Command{}

	_, err := c.ServeCommand(ctx, rec, cmd)
	assert.IsType(t, &InvalidRepoError{}, err)
}
