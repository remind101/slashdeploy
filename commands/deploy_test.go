package commands

import (
	"testing"

	"golang.org/x/net/context"

	"github.com/ejholmes/slash"
	"github.com/ejholmes/slash/slashtest"
	"github.com/ejholmes/slashdeploy"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestDeploy_InvalidRepo(t *testing.T) {
	d := new(mockDeploymentsService)
	c := &Deploy{deploymentsService: d}

	ctx := slash.WithParams(context.Background(), map[string]string{})
	rec := slashtest.NewRecorder()
	cmd := slash.Command{}

	_, err := c.ServeCommand(ctx, rec, cmd)
	assert.IsType(t, &InvalidRepoError{}, err)
}

func TestDeploy_Defaults(t *testing.T) {
	d := new(mockDeploymentsService)
	c := &Deploy{deploymentsService: d}

	ctx := slash.WithParams(context.Background(), map[string]string{
		"repo": "ejholmes/acme-inc",
	})
	rec := slashtest.NewRecorder()
	cmd := slash.Command{}

	d.On("CreateDeployment", slashdeploy.DeploymentRequest{
		Owner:       "ejholmes",
		Repository:  "acme-inc",
		Ref:         "master",
		Environment: "production",
	}).Return(&slashdeploy.Deployment{}, nil)

	_, err := c.ServeCommand(ctx, rec, cmd)
	assert.NoError(t, err)
}

func TestDeploy_Overrides(t *testing.T) {
	d := new(mockDeploymentsService)
	c := &Deploy{deploymentsService: d}

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

type mockDeploymentsService struct {
	mock.Mock
}

func (m *mockDeploymentsService) CreateDeployment(ctx context.Context, request slashdeploy.DeploymentRequest) (*slashdeploy.Deployment, error) {
	args := m.Called(request)
	return args.Get(0).(*slashdeploy.Deployment), args.Error(1)
}
