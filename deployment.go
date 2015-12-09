package slashdeploy

import "fmt"

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
