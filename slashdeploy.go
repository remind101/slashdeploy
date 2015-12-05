package slashdeploy

import "golang.org/x/oauth2"

// Defaults unless overriden by the repository settings.
var (
	DefaultEnvironment = "production"
	DefaultRef         = "master"
)

func init() {
	// We cannot set the client_secret in the auth header, which is the
	// default behavior of package oauth2.
	oauth2.RegisterBrokenAuthHeaderProvider("https://slack.com/api")
}
