package main

import (
	"fmt"
	"net/http"
	"os"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/github"

	"github.com/codegangsta/cli"
	"github.com/ejholmes/slash"
	"github.com/ejholmes/slashdeploy"
	"github.com/ejholmes/slashdeploy/commands"
	"github.com/ejholmes/slashdeploy/deployments"
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
	sd := newSlashDeploy(c)
	s := slashdeploy.NewServer(sd, newCommands(sd, c))
	must(http.ListenAndServe(fmt.Sprintf(":%s", port), s))
}

func newSlashDeploy(c *cli.Context) *slashdeploy.SlashDeploy {
	return &slashdeploy.SlashDeploy{
		Users: slashdeploy.NewMemUsersStore(),
		SlackOAuth: &oauth2.Config{
			ClientID:     c.String("slack.client.id"),
			ClientSecret: c.String("slash.client.secret"),
			Scopes:       slashdeploy.DefaultSlackScopes,
			Endpoint:     slashdeploy.DefaultSlackEndpoint,
		},
		GitHubOAuth: &oauth2.Config{
			ClientID:     c.String("github.client.id"),
			ClientSecret: c.String("github.client.secret"),
			Scopes:       []string{"repo_deployment"},
			Endpoint:     github.Endpoint,
		},
		BuildDeployer: func(user *slashdeploy.User) deployments.Deployer {
			return deployments.NullDeployer
		},
	}
}

func newCommands(s *slashdeploy.SlashDeploy, c *cli.Context) slash.Handler {
	return commands.New(c.String("slack.verification.token"), commands.SubCommands{
		Help: commands.Help,
		Deploy: s.GitHubAuthenticate(&commands.Deploy{
			Deployer: s,
		}),
	})
}

func must(err error) {
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}
