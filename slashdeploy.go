package slashdeploy

import (
	"github.com/ejholmes/slashdeploy/deployments"
	"golang.org/x/net/context"
	"golang.org/x/oauth2"
)

// Defaults unless overriden by the repository settings.
var (
	DefaultEnvironment = "production"
	DefaultRef         = "master"
)

func init() {
	// We cannot set the client_secret in the auth header, which is the
	// default behavior of package oauth2.
	oauth2.RegisterBrokenAuthHeaderProvider("https://slack.com/api")
}

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
