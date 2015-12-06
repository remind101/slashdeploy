package slashdeploy

import (
	"errors"
	"fmt"
	"regexp"
	"strings"

	"github.com/ejholmes/slash"
	"github.com/ejholmes/slashdeploy/deployments"
	"golang.org/x/net/context"
)

// Command is a slash.Handler that handles the base /deploy command.
type Command struct {
	slash.Handler
	deployments.Deployer
}

func newCommand(verificationToken string) *Command {
	c := &Command{}

	d := slash.NewMux()
	d.Match(slash.MatchSubcommand("help"), slash.HandlerFunc(c.Help))

	deploy := authenticate(slash.HandlerFunc(c.Deploy), &usersStore{})
	d.MatchText(regexp.MustCompile(`(?P<repo>\S+?)@(?P<ref>\S+?) to (?P<environment>\S+?)$`), deploy)
	d.MatchText(regexp.MustCompile(`(?P<repo>\S+?) to (?P<environment>\S+?)$`), deploy)
	d.MatchText(regexp.MustCompile(`(?P<repo>\S+?)@(?P<ref>\S+?)$`), deploy)
	d.MatchText(regexp.MustCompile(`(?P<repo>\S+?)$`), deploy)

	r := slash.NewMux()
	r.Command("/deploy", verificationToken, d)

	c.Handler = r

	return c
}

// Help handles the /deploy help subcommand.
func (c *Command) Help(ctx context.Context, r slash.Responder, command slash.Command) (slash.Response, error) {
	return slash.Reply(helpText), nil
}

func (c *Command) Deploy(ctx context.Context, r slash.Responder, command slash.Command) (slash.Response, error) {
	params := slash.Params(ctx)
	owner, repo, err := splitRepo(params["repo"])
	if err != nil {
		return slash.NoResponse, err
	}

	environment := params["environment"]
	if environment == "" {
		environment = DefaultEnvironment
	}

	ref := params["ref"]
	if ref == "" {
		ref = DefaultRef
	}

	req := deployments.DeploymentRequest{
		Owner:       owner,
		Repository:  repo,
		Environment: environment,
		Ref:         ref,
	}
	_, err = c.Deployer.Deploy(req, &statuses{DeploymentRequest: req, Responder: r})

	return slash.Say(fmt.Sprintf("Created deployment request for %s. I'll let you know when it starts.", fmtDeploymentRequest(req))), nil
}

// statuses is an implementation of the deployments.Statuses interface, that uses a
// slash.Responder to notify the user about the deployment.
type statuses struct {
	deployments.DeploymentRequest
	slash.Responder
}

func (e *statuses) Status(status deployments.Status) error {
	switch status.Status {
	case deployments.StatusStarted:
		return e.Respond(slash.Reply(fmt.Sprintf("Your deployment of %s has started: %s", fmtDeploymentRequest(e.DeploymentRequest), status.URL)))
	case deployments.StatusSucceeded:
		return e.Respond(slash.Reply(fmt.Sprintf("Your deployment of %s has completed successfully: %s", fmtDeploymentRequest(e.DeploymentRequest), status.URL)))
	default:
		return nil
	}
}

func fmtDeploymentRequest(req deployments.DeploymentRequest) string {
	return fmt.Sprintf("%s/%s@%s to %s", req.Owner, req.Repository, req.Ref, req.Environment)
}

var errInvalidRepo = errors.New("repo not valid")

func splitRepo(fullName string) (repo, owner string, err error) {
	parts := strings.SplitN(fullName, "/", 2)
	if len(parts) != 2 {
		err = errInvalidRepo
		return
	}

	repo, owner = parts[0], parts[1]
	return
}

func authenticate(h slash.Handler, s UsersStore) slash.Handler {
	return slash.HandlerFunc(func(ctx context.Context, r slash.Responder, c slash.Command) (slash.Response, error) {
		u, err := s.Find(c.UserID)
		if err != nil {
			return slash.NoResponse, err
		}

		if u == nil {
			//return slash.Reply("Please authenticate first"), nil
		}

		return h.ServeCommand(WithUser(ctx, u), r, c)
	})
}

var helpText = `To deploy a repo to the default environment: /deploy REPO
To deploy a repo to a specific environment: /deploy REPO to ENVIRONMENT
To deploy a repo to a specific branch: /deploy REPO@REF to ENVIRONMENT`
