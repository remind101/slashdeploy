package commands

const helpText = `To deploy a repo to the default environment: /deploy REPO
To deploy a repo to a specific environment: /deploy REPO to ENVIRONMENT
To deploy a repo to a specific branch: /deploy REPO@REF to ENVIRONMENT`

// Help is a slash.Handler that responds with the help text.
var Help = replyHandler(helpText)
