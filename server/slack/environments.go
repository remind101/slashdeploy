package slack

import (
	"fmt"
	"strings"

	"github.com/ejholmes/slash"
	"golang.org/x/net/context"
)

type EnvironmentsCommand struct {
	client
}

func (c *EnvironmentsCommand) ServeCommand(ctx context.Context, r slash.Responder, _ slash.Command) error {
	params := slash.Params(ctx)

	envs, err := c.ListEnvironments(params["repo"])
	if err != nil {
		return err
	}

	if len(envs) == 0 {
		return r.Respond(slash.Say(fmt.Sprintf("No known environments for %s", params["repo"])))
	}

	lines := []string{
		fmt.Sprintf("I know about these environments for %s", params["repo"]),
	}
	for _, env := range envs {
		lines = append(lines, fmt.Sprintf("* %s", env.Name))
	}

	return r.Respond(slash.Say(strings.Join(lines, "\n")))
}
