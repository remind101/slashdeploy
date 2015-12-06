package github

import (
	"fmt"

	"golang.org/x/net/context"

	"github.com/ejholmes/slashdeploy/deployments"
	"github.com/google/go-github/github"
)

type githubClient interface {
	CreateDeployment(owner, repo string, request *github.DeploymentRequest) (*github.Deployment, *github.Response, error)
}

// Deployer implements the deployer.Deployer interface using GitHub Deployments.
type Deployer struct {
	github githubClient
}

func (d *Deployer) Deploy(ctx context.Context, req deployments.DeploymentRequest) (*deployments.Deployment, error) {
	gd, _, err := d.github.CreateDeployment(req.Owner, req.Repository, &github.DeploymentRequest{
		Environment: github.String(req.Environment),
		Ref:         github.String(req.Ref),
		AutoMerge:   github.Bool(false),
		Task:        github.String("deploy"),
	})
	if err != nil {
		return nil, err
	}

	return &deployments.Deployment{
		ID: fmt.Sprintf("%d", *gd.ID),
	}, nil
}
