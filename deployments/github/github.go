package github

import (
	"fmt"
	"strings"

	"golang.org/x/net/context"
	"golang.org/x/oauth2"

	"github.com/ejholmes/slashdeploy"
	"github.com/google/go-github/github"
)

type githubClient interface {
	CreateDeployment(owner, repo string, request *github.DeploymentRequest) (*github.Deployment, *github.Response, error)
}

// CommitStatusChecksError is an error implementation that is returned when the
// deployment fails because the commit status checks are failing for the given
// git sha.
type CommitStatusChecksError struct {
	Ref string

	ErrorResponse *github.ErrorResponse // Original github error.
}

func (e *CommitStatusChecksError) Error() string {
	return fmt.Sprintf("Commit status checks failed for %s.", e.Ref)
}

// NoRefError is an error implementation that is returned when the supplied ref
// doesn't exist on GitHub.
type NoRefError struct {
	Ref string

	ErrorResponse *github.ErrorResponse // Original github error.
}

func (e *NoRefError) Error() string {
	return fmt.Sprintf("No ref found for %s. Did you push it to GitHub?", e.Ref)
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

func (d *Deployer) Deploy(ctx context.Context, req slashdeploy.DeploymentRequest) error {
	_, _, err := d.github.CreateDeployment(req.Owner, req.Repository, &github.DeploymentRequest{
		Environment: github.String(req.Environment),
		Ref:         github.String(req.Ref),
		AutoMerge:   github.Bool(false),
		Task:        github.String("deploy"),
	})
	if err != nil {
		if err, ok := err.(*github.ErrorResponse); ok {
			if strings.HasPrefix(err.Message, "Conflict: Commit status checks failed for") {
				return &CommitStatusChecksError{
					Ref:           req.Ref,
					ErrorResponse: err,
				}
			} else if strings.HasPrefix(err.Message, "No ref found for") {
				return &NoRefError{
					Ref:           req.Ref,
					ErrorResponse: err,
				}
			}
		}
		return err
	}

	return nil
}
