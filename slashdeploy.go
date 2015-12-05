package slashdeploy

import (
	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
)

// Defaults unless overriden by the repository settings.
var (
	DefaultEnvironment = "production"
	DefaultRef         = "master"
	DefaultTask        = "deploy"
	DefaultAutoMerge   = false
)

func init() {
	// We cannot set the client_secret in the auth header, which is the
	// default behavior of package oauth2.
	oauth2.RegisterBrokenAuthHeaderProvider("https://slack.com/api")
}

// Deployer is something that can create a GitHub Deployment.
type Deployer interface {
	CreateDeployment(owner, repo string, request *github.DeploymentRequest) (*github.Deployment, *github.Response, error)
}

type DeployerFunc func(owner, repo string, request *github.DeploymentRequest) (*github.Deployment, *github.Response, error)

func (fn DeployerFunc) CreateDeployment(owner, repo string, request *github.DeploymentRequest) (*github.Deployment, *github.Response, error) {
	return fn(owner, repo, request)
}

// NullDeployer is a Deployer implementation that does nothing.
var NullDeployer = DeployerFunc(func(owner, repo string, request *github.DeploymentRequest) (*github.Deployment, *github.Response, error) {
	return &github.Deployment{}, nil, nil
})
