package deployments

import (
	"github.com/ejholmes/slashdeploy"
	"golang.org/x/net/context"
)

// Service object for creating deployments.
type Service struct {
	// BuildDeployer should return a Deployer instance to create the
	// deployment as the given user.
	BuildDeployer func(*slashdeploy.User) Deployer
}

// CreateDeployment creates a new GitHub deployment as the given user.
func (s *Service) CreateDeployment(ctx context.Context, req slashdeploy.DeploymentRequest) (*slashdeploy.Deployment, error) {
	user, ok := slashdeploy.UserFromContext(ctx)
	if !ok {
		panic("user should be set")
	}

	err := s.BuildDeployer(user).Deploy(req)
	if err != nil {
		return nil, err
	}

	return &slashdeploy.Deployment{}, nil
}

// Deployer represents something that can create deployment requests.
type Deployer interface {
	// Deploy creates the deployment.
	Deploy(slashdeploy.DeploymentRequest) error
}

type DeployerFunc func(slashdeploy.DeploymentRequest) error

func (fn DeployerFunc) Deploy(req slashdeploy.DeploymentRequest) error {
	return fn(req)
}

// NullDeployer is a Deployer implementation that does nothing.
var NullDeployer = DeployerFunc(func(req slashdeploy.DeploymentRequest) error {
	return nil
})
