package deployments

import (
	"testing"

	"github.com/ejholmes/slashdeploy"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"golang.org/x/net/context"
)

func TestService_CreateDeployment(t *testing.T) {
	u := &slashdeploy.User{}
	d := new(mockDeployer)
	s := &Service{BuildDeployer: func(user *slashdeploy.User) Deployer {
		assert.Equal(t, u, user)
		return d
	}}

	d.On("Deploy", slashdeploy.DeploymentRequest{
		Owner:       "ejholmes",
		Repository:  "acme-inc",
		Ref:         "master",
		Environment: "production",
	}).Return(nil)

	ctx := slashdeploy.WithUser(context.Background(), u)
	_, err := s.CreateDeployment(ctx, slashdeploy.DeploymentRequest{
		Owner:       "ejholmes",
		Repository:  "acme-inc",
		Ref:         "master",
		Environment: "production",
	})
	assert.NoError(t, err)
}

func TestService_CreateDeployment_NoUser(t *testing.T) {
	s := &Service{}
	assert.Panics(t, func() {
		s.CreateDeployment(context.Background(), slashdeploy.DeploymentRequest{})
	})
}

type mockDeployer struct {
	mock.Mock
}

func (m *mockDeployer) Deploy(req slashdeploy.DeploymentRequest) error {
	args := m.Called(req)
	return args.Error(0)
}
