package slashdeploy

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"golang.org/x/net/context"
)

func TestDeploymentsService_CreateDeployment(t *testing.T) {
	u := &User{}
	d := new(mockDeployer)
	s := &DeploymentsService{
		Client: &Client{
			BuildDeployer: func(user *User) Deployer {
				assert.Equal(t, u, user)
				return d
			},
		},
	}

	d.On("Deploy", DeploymentRequest{
		Owner:       "ejholmes",
		Repository:  "acme-inc",
		Ref:         "master",
		Environment: "production",
	}).Return(nil)

	ctx := WithUser(context.Background(), u)
	_, err := s.CreateDeployment(ctx, DeploymentRequest{
		Owner:       "ejholmes",
		Repository:  "acme-inc",
		Ref:         "master",
		Environment: "production",
	})
	assert.NoError(t, err)
}

func TestDeploymentsService_CreateDeployment_NoUser(t *testing.T) {
	s := &DeploymentsService{}
	assert.Panics(t, func() {
		s.CreateDeployment(context.Background(), DeploymentRequest{})
	})
}

type mockDeployer struct {
	mock.Mock
}

func (m *mockDeployer) Deploy(req DeploymentRequest) error {
	args := m.Called(req)
	return args.Error(0)
}
