// Pacakge slack contains slash.Handler's for the SlashDeploy slack commands.
package slack

import (
	"regexp"

	"github.com/ejholmes/slash"
	"github.com/ejholmes/slashdeploy"
	"golang.org/x/net/context"
)

// Client represents the interface of a slashdeploy.Client that we use.
type Client interface {
	CreateDeployment(context.Context, slashdeploy.DeploymentRequest) (*slashdeploy.Deployment, error)
}

// Handler is a slash.Handler for serving the slack slash commands.
type Handler struct {
	Help   slash.Handler
	Deploy *DeployCommand

	client Client
}

// New returns a new slash.Handler that sets up routes to the subcommands.
func NewHandler(c Client) *Handler {
	h := &Handler{client: c}
	h.Help = HelpCommand
	h.Deploy = &DeployCommand{Handler: h}
	return h
}

// New returns a new slash.Handler to handle the slack slash commands.
func New(token string, c Client) slash.Handler {
	return Route(token, NewHandler(c))
}

// Route returns a new slash.Handler for serving commands.
func Route(token string, h *Handler) slash.Handler {
	return route(token, handlers{
		Help:   h.Help,
		Deploy: h.Deploy,
	})
}

type handlers struct {
	Help   slash.Handler
	Deploy slash.Handler
}

func route(token string, h handlers) slash.Handler {
	d := slash.NewMux()
	d.Match(slash.MatchSubcommand("help"), h.Help)

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
	return slash.HandlerFunc(func(ctx context.Context, r slash.Responder, c slash.Command) (slash.Response, error) {
		return slash.Reply(text), nil
	})
}
