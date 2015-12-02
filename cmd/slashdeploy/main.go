package main

import (
	"fmt"
	"net/http"
	"os"

	"github.com/codegangsta/cli"
	"github.com/gorilla/mux"
)

var commands = []cli.Command{
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
		},
		Action: runServer,
	},
}

func main() {
	app := cli.NewApp()
	app.Name = "slashdeploy"
	app.Usage = "Trigger GitHub Deployments with Slack slash commands"
	app.Commands = commands
	app.Run(os.Args)
}

func runServer(c *cli.Context) {
	port := c.String("port")
	r := mux.NewRouter()
	must(http.ListenAndServe(fmt.Sprintf(":%s", port), r))
}

func must(err error) {
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}
