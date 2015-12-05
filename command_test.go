package slashdeploy

import (
	"testing"

	"github.com/ejholmes/slash"
	"github.com/ejholmes/slash/slashtest"
	"github.com/ejholmes/slashdeploy/deployments"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"golang.org/x/net/context"
)

func TestCommand_Help(t *testing.T) {
	c := newCommand("token")

	rec := slashtest.NewRecorder()
	cmd := slash.Command{
		Command: "/deploy",
		Text:    "help",
		Token:   "token",
	}

	resp, err := c.ServeCommand(context.Background(), rec, cmd)
	assert.NoError(t, err)
	assert.Equal(t, helpText, resp.Text)
}

func TestCommand_Deploy_Basic(t *testing.T) {
	d := new(mockDeployer)
	c := newCommand("token")
	c.Deployer = d

	rec := slashtest.NewRecorder()
	cmd := slash.Command{
		Command: "/deploy",
		Text:    "remind101/acme-inc",
		Token:   "token",
	}

	d.On("Deploy", deployments.DeploymentRequest{
		Owner:       "remind101",
		Repository:  "acme-inc",
		Environment: "production",
		Ref:         "master",
	}).Return(&deployments.Deployment{}, nil)

	_, err := c.ServeCommand(context.Background(), rec, cmd)
	assert.NoError(t, err)

	d.AssertExpectations(t)
}

func TestCommand_Deploy_WithEnvironment(t *testing.T) {
	d := new(mockDeployer)
	c := newCommand("token")
	c.Deployer = d

	rec := slashtest.NewRecorder()
	cmd := slash.Command{
		Command: "/deploy",
		Text:    "remind101/acme-inc to staging",
		Token:   "token",
	}

	d.On("Deploy", deployments.DeploymentRequest{
		Owner:       "remind101",
		Repository:  "acme-inc",
		Environment: "staging",
		Ref:         "master",
	}).Return(&deployments.Deployment{}, nil)

	_, err := c.ServeCommand(context.Background(), rec, cmd)
	assert.NoError(t, err)

	d.AssertExpectations(t)
}

func TestCommand_Deploy_WithRef(t *testing.T) {
	d := new(mockDeployer)
	c := newCommand("token")
	c.Deployer = d

	rec := slashtest.NewRecorder()
	cmd := slash.Command{
		Command: "/deploy",
		Text:    "remind101/acme-inc@topic-branch",
		Token:   "token",
	}

	d.On("Deploy", deployments.DeploymentRequest{
		Owner:       "remind101",
		Repository:  "acme-inc",
		Environment: "production",
		Ref:         "topic-branch",
	}).Return(&deployments.Deployment{}, nil)

	_, err := c.ServeCommand(context.Background(), rec, cmd)
	assert.NoError(t, err)

	d.AssertExpectations(t)
}

func TestCommand_Deploy_WithRefAndEnvironment(t *testing.T) {
	d := new(mockDeployer)
	c := newCommand("token")
	c.Deployer = d

	rec := slashtest.NewRecorder()
	cmd := slash.Command{
		Command: "/deploy",
		Text:    "remind101/acme-inc@topic-branch to staging",
		Token:   "token",
	}

	d.On("Deploy", deployments.DeploymentRequest{
		Owner:       "remind101",
		Repository:  "acme-inc",
		Environment: "staging",
		Ref:         "topic-branch",
	}).Return(&deployments.Deployment{}, nil)

	_, err := c.ServeCommand(context.Background(), rec, cmd)
	assert.NoError(t, err)

	d.AssertExpectations(t)
}

type mockDeployer struct {
	mock.Mock
}

func (m *mockDeployer) Deploy(request deployments.DeploymentRequest, u deployments.Events) (*deployments.Deployment, error) {
	args := m.Called(request)
	return args.Get(0).(*deployments.Deployment), args.Error(1)
}
