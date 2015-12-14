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

func (c *EnvironmentsCommand) ServeCommand(ctx context.Context, r slash.Responder, _ slash.Command) (slash.Response, error) {
	params := slash.Params(ctx)

	envs, err := c.ListEnvironments(params["repo"])
	if err != nil {
		return slash.NoResponse, err
	}

	if len(envs) == 0 {
		return slash.Say(fmt.Sprintf("No known environments for %s", params["repo"])), nil
	}

	lines := []string{
		fmt.Sprintf("I know about these environments for %s", params["repo"]),
	}
	for _, env := range envs {
		lines = append(lines, fmt.Sprintf("* %s", env.Name))
	}

	return slash.Say(strings.Join(lines, "\n")), nil
}
