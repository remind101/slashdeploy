// Pacakge slack contains slash.Handler's for the SlashDeploy slack commands.
package slack

import (
	"regexp"

	"github.com/ejholmes/slash"
	"github.com/ejholmes/slashdeploy"
	"golang.org/x/net/context"
)

// client represents the interface of a slashdeploy.Client that we use.
type client interface {
	CreateDeployment(context.Context, slashdeploy.DeploymentRequest) (*slashdeploy.Deployment, error)
	ListEnvironments(string) ([]*slashdeploy.Environment, error)
}

// Commands is a slash.Handler for serving the slack slash commands.
type Commands struct {
	Help         slash.Handler
	Deploy       *DeployCommand
	Environments *EnvironmentsCommand

	client client
}

// newCommands returns a new slash.Handler that sets up routes to the subcommands.
func newCommands(c client) *Commands {
	h := &Commands{client: c}
	h.Help = HelpCommand
	h.Deploy = &DeployCommand{client: c}
	h.Environments = &EnvironmentsCommand{client: c}
	return h
}

// New returns a new slash.Handler to handle the slack slash commands.
func New(token string, c *slashdeploy.Client) slash.Handler {
	return newHandler(token, c)
}

func newHandler(token string, c client) slash.Handler {
	return routeCommands(token, newCommands(c))
}

// routeCommands returns a new slash.Handler for serving commands.
func routeCommands(token string, c *Commands) slash.Handler {
	return route(token, handlers{
		Help:         c.Help,
		Deploy:       c.Deploy,
		Environments: c.Environments,
	})
}

type handlers struct {
	Help         slash.Handler
	Deploy       slash.Handler
	Environments slash.Handler
}

func route(token string, h handlers) slash.Handler {
	d := slash.NewMux()
	d.Match(slash.MatchSubcommand("help"), h.Help)

	d.MatchText(regexp.MustCompile(`where (?P<repo>\S+?)\??$`), h.Environments)

	deploy := h.Deploy
	d.MatchText(regexp.MustCompile(`(?P<repo>\S+?)@(?P<ref>\S+?) to (?P<environment>\S+?)$`), deploy)
	d.MatchText(regexp.MustCompile(`(?P<repo>\S+?) to (?P<environment>\S+?)$`), deploy)
	d.MatchText(regexp.MustCompile(`(?P<repo>\S+?)@(?P<ref>\S+?)$`), deploy)
	d.MatchText(regexp.MustCompile(`(?P<repo>\S+?)$`), deploy)

	r := slash.NewMux()
	r.Command("/deploy", token, d)

	return r
}

// replyHandler returns a slash.Handler that just replies to the user with the
// text.
func replyHandler(text string) slash.Handler {
	return slash.HandlerFunc(func(ctx context.Context, r slash.Responder, c slash.Command) error {
		return r.Respond(slash.Reply(text))
	})
}
