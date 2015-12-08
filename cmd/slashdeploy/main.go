package main

import (
	"fmt"
	"net/http"
	"os"

	"github.com/codegangsta/cli"
)

var cmds = []cli.Command{
	{
		Name:  "server",
		Usage: "Start the web server",
		Flags: []cli.Flag{
			cli.StringFlag{
				Name:   "port",
				Value:  "8080",
				EnvVar: "PORT",
				Usage:  "port to bind to",
			},
			cli.StringFlag{
				Name:   "state.key",
				Value:  "",
				EnvVar: "STATE_KEY",
				Usage:  "Key used to sign oauth state.",
			},
			cli.StringFlag{
				Name:   "slack.verification.token",
				Value:  "",
				EnvVar: "SLACK_VERIFICATION_TOKEN",
				Usage:  "The shared secret between SlashDeploy and Slack",
			},
			cli.StringFlag{
				Name:   "slack.client.id",
				Value:  "",
				EnvVar: "SLACK_CLIENT_ID",
				Usage:  "OAuth client id",
			},
			cli.StringFlag{
				Name:   "slack.client.secret",
				Value:  "",
				EnvVar: "SLACK_CLIENT_SECRET",
				Usage:  "OAuth client secret",
			},
			cli.StringFlag{
				Name:   "github.client.id",
				Value:  "",
				EnvVar: "GITHUB_CLIENT_ID",
				Usage:  "OAuth client id",
			},
			cli.StringFlag{
				Name:   "github.client.secret",
				Value:  "",
				EnvVar: "GITHUB_CLIENT_SECRET",
				Usage:  "OAuth client secret",
			},
		},
		Action: runServer,
	},
}

func main() {
	app := cli.NewApp()
	app.Name = "slashdeploy"
	app.Usage = "Trigger GitHub Deployments with Slack slash commands"
	app.Commands = cmds
	app.Run(os.Args)
}

func runServer(c *cli.Context) {
	port := c.String("port")
	f := newFactory(c)
	must(http.ListenAndServe(fmt.Sprintf(":%s", port), f.Server()))
}

func must(err error) {
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}
