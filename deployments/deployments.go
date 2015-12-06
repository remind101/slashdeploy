package deployments

import (
	"fmt"
	"time"
)

type Deployment struct {
	// A unique identifier for the deployment request that was created.
	ID string
}

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

func (d *DeploymentRequest) String() string {
	return fmt.Sprintf("%s/%s@%s to %s", d.Owner, d.Repository, d.Ref, d.Environment)
}

type DeploymentStatus int

const (
	StatusPending DeploymentStatus = iota
	StatusStarted
	StatusSucceeded
	StatusFailed
)

type Status struct {
	// The status type.
	Status DeploymentStatus

	// A url to view details about this deployment status.
	URL string
}

// Deployer represents something that can create deployment requests.
type Deployer interface {
	// When deploy is called, the implementer should create a deployment
	// request then immediately return. The implementer can use the provided
	// Statuses to notify the consumer about status updates.
	Deploy(DeploymentRequest, Statuses) (*Deployment, error)
}

type DeployerFunc func(DeploymentRequest, Statuses) (*Deployment, error)

func (fn DeployerFunc) Deploy(req DeploymentRequest, u Statuses) (*Deployment, error) {
	return fn(req, u)
}

type Statuses interface {
	Status(Status) error
}

// NullDeployer is a Deployer implementation that does nothing.
var NullDeployer = DeployerFunc(func(req DeploymentRequest, e Statuses) (*Deployment, error) {
	return &Deployment{ID: "1"}, nil
})

var FakeDeployer = DeployerFunc(func(req DeploymentRequest, e Statuses) (*Deployment, error) {
	go func() {
		<-time.After(5 * time.Second)
		e.Status(Status{
			Status: StatusStarted,
			URL:    "https://www.google.com",
		})

		<-time.After(5 * time.Second)
		e.Status(Status{
			Status: StatusSucceeded,
			URL:    "https://www.google.com",
		})
	}()
	return &Deployment{ID: "1"}, nil
})
