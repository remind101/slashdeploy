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

	var lines []string
	for _, env := range envs {
		lines = append(lines, fmt.Sprintf("* %s", env.Name))
	}

	return slash.Reply(strings.Join(lines, "\n")), nil
}
