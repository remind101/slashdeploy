package github

import (
	"fmt"

	"golang.org/x/net/context"
	"golang.org/x/oauth2"

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

// NewDeployer returns a new Deployer instance authenticated with the access
// token.
func NewDeployer(token string) *Deployer {
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: token},
	)
	tc := oauth2.NewClient(oauth2.NoContext, ts)

	return &Deployer{
		github: github.NewClient(tc).Repositories,
	}
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
