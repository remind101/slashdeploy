package slashdeploy

import (
	"github.com/ejholmes/slashdeploy/deployments"
	"golang.org/x/net/context"
)

type SlashDeploy struct {
	Users UsersStore

	// BuildDeployer builds a deployments.Deployer so that the deployment
	// request can be created by the associated GitHub user.
	BuildDeployer func(*User) deployments.Deployer
}

func (d *SlashDeploy) Deploy(ctx context.Context, req deployments.DeploymentRequest) (*deployments.Deployment, error) {
	user, ok := UserFromContext(ctx)
	if !ok {
		panic("user should be set")
	}

	return d.BuildDeployer(user).Deploy(ctx, req)
}
