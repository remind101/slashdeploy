package main

import (
	"fmt"
	"net/http"
	"os"

	"github.com/codegangsta/cli"
	"github.com/ejholmes/slashdeploy"
	"github.com/ejholmes/slashdeploy/deployments/github"
	"github.com/ejholmes/slashdeploy/server"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"

	slackoauth "github.com/ejholmes/slashdeploy/pkg/oauth2/slack"
	"golang.org/x/oauth2"
	githuboauth "golang.org/x/oauth2/github"
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
				Usage:  "Port to bind to",
			},
			cli.StringFlag{
				Name:   "db",
				Value:  "8080",
				EnvVar: "DATABASE_URL",
				Usage:  "Postgres connection string",
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
	db := sqlx.MustConnect("postgres", c.String("db"))
	must(slashdeploy.MigrateUp(db, "postgres"))
	s := newServer(newClient(db), c)
	must(http.ListenAndServe(fmt.Sprintf(":%s", port), s))
}

func newClient(db *sqlx.DB) *slashdeploy.Client {
	s := slashdeploy.New(db)
	s.BuildDeployer = func(user *slashdeploy.User) slashdeploy.Deployer {
		return github.NewDeployer(*user.GitHubToken)
	}
	return s
}

func newServer(s *slashdeploy.Client, c *cli.Context) http.Handler {
	return server.New(s, server.Config{
		OAuth: &server.OAuthConfig{
			Slack: &oauth2.Config{
				ClientID:     c.String("slack.client.id"),
				ClientSecret: c.String("slack.client.secret"),
				Scopes:       []string{"commands"},
				Endpoint:     slackoauth.Endpoint,
			},
			GitHub: &oauth2.Config{
				ClientID:     c.String("github.client.id"),
				ClientSecret: c.String("github.client.secret"),
				Scopes:       []string{"repo_deployment"},
				Endpoint:     githuboauth.Endpoint,
			},
		},
		StateKey:               []byte(c.String("state.key")),
		SlackVerificationToken: c.String("slack.verification.token"),
	})
}

func must(err error) {
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}
