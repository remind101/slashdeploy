package slashdeploy

import (
	"fmt"

	"golang.org/x/net/context"
)

// Defaults unless overriden by the repository settings.
var (
	DefaultEnvironment = "production"
	DefaultRef         = "master"
)

// Deployment represents a deployment that was created.
type Deployment struct {
	// A unique identifier for the deployment request that was created.
	ID string
}

// DeploymentRequest represents options that are passed when creating a new
// deployment.
type DeploymentRequest struct {
	// The User or Organization that owns the repository.
	Owner string

	// The name of the repository to deploy.
	Repository string

	// The git ref to deploy.
	Ref string

	// The environment to deploy to.
	Environment string
}

func (d DeploymentRequest) String() string {
	return fmt.Sprintf("%s/%s@%s to %s", d.Owner, d.Repository, d.Ref, d.Environment)
}

// DeploymentsService is a service for interacting with deployments.
type DeploymentsService struct {
	*Client
}

// CreateDeployment creates a new GitHub deployment as the given user.
func (s *DeploymentsService) CreateDeployment(ctx context.Context, req DeploymentRequest) (*Deployment, error) {
	user, ok := UserFromContext(ctx)
	if !ok {
		panic("user should be set")
	}

	if req.Environment == "" {
		req.Environment = DefaultEnvironment
	}

	if req.Ref == "" {
		req.Ref = DefaultRef
	}

	err := s.BuildDeployer(user).Deploy(req)
	if err != nil {
		return nil, err
	}

	return &Deployment{}, nil
}

// Deployer represents something that can create deployment requests.
type Deployer interface {
	// Deploy creates the deployment.
	Deploy(DeploymentRequest) error
}

type DeployerFunc func(DeploymentRequest) error

func (fn DeployerFunc) Deploy(req DeploymentRequest) error {
	return fn(req)
}

// NullDeployer is a Deployer implementation that does nothing.
var NullDeployer = DeployerFunc(func(req DeploymentRequest) error {
	return nil
})
