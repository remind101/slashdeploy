package slashdeploy

import (
	"github.com/ejholmes/slash"
	"golang.org/x/net/context"
)

// Command is a slash.Handler that handles the /deploy command.
type Command struct {
	slash.Handler
}

func newCommand(verificationToken string) *Command {
	c := &Command{}

	d := slash.NewMux()
	d.Match(slash.MatchSubcommand("help"), slash.HandlerFunc(c.Help))

	r := slash.NewMux()
	r.Command("/deploy", verificationToken, d)

	c.Handler = r

	return c
}

// Deploy handles the /deploy command.
func (c *Command) Help(ctx context.Context, r slash.Responder, command slash.Command) (slash.Response, error) {
	return slash.Reply(helpText), nil
}

var helpText = `To deploy a repo to the default environment: /deploy REPO
To deploy a repo to a specific environment: /deploy REPO to ENVIRONMENT`
