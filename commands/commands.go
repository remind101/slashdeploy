// Pacakge commands contains slash.Handler's for the SlashDeploy commands.
package commands

import (
	"regexp"

	"github.com/ejholmes/slash"
	"golang.org/x/net/context"
)

// SubCommands is provided to New when building a new SlashDeploy command
// handler.
type SubCommands struct {
	Help   slash.Handler
	Deploy slash.Handler
}

// New returns a new slash.Handler that sets up routes to the subcommands.
func New(token string, cmds SubCommands) slash.Handler {
	d := slash.NewMux()
	d.Match(slash.MatchSubcommand("help"), cmds.Help)

	deploy := cmds.Deploy
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
