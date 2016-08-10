# SlashDeploy [![Build Status](https://travis-ci.org/ejholmes/slashdeploy.svg?branch=master)](https://travis-ci.org/ejholmes/slashdeploy) [![Code Climate](https://codeclimate.com/github/ejholmes/slashdeploy/badges/gpa.svg)](https://codeclimate.com/github/ejholmes/slashdeploy)

[SlashDeploy](https://slashdeploy.io) is a web app for triggering [GitHub Deployments](https://developer.github.com/v3/repos/deployments/) via a `/deploy` command in Slack.

## Installation

SlashDeploy is already hosted at https://slashdeploy.io. All you have to do is add it to your Slack team:

<a href="https://slashdeploy.io/slack/install"><img alt="Add to Slack" height="40" width="139" src="https://platform.slack-edge.com/img/add_to_slack@2x.png"></a>

## Usage

Deploy a repository to the default environment (production):

```console
/deploy ejholmes/acme-inc
```

Deploy a repository to a specific environment:

```console
/deploy ejholmes/acme-inc to staging
```

Deploy a branch:

```console
/deploy ejholmes/acme-inc@topic-branch to staging
```

And more at <https://slashdeploy.io/docs>.

## Development

### Using ngrok

1. Install [ngrok](https://ngrok.com/) and run `./ngrok http 3000`
2. Create a [Slack App](https://api.slack.com/apps/new), set your Slack Redirect URI to `http://xxx.ngrok.io/auth/slack/callback` and set your Interactive Messages Request URL to `https://xxx.ngrok.io/slack/actions`
3. Listen to `/deploy` commands by setting the Request URL to `https://xxx.ngrok.io/slack/commands`
4. Register a new [Github OAuth application](https://github.com/settings/applications/new)
5. Set your Github Authorization callback URL to `http://xxx.ngrok.io/auth/github/callback`
6. Using Slack and Github app credentials, set the following environment variables in a `.env` file:
  - `GITHUB_CLIENT`
  - `SLACK_CLIENT`
  - `GITHUB_CLIENT_ID`
  - `GITHUB_CLIENT_SECRET`
  - `SLACK_CLIENT_ID`
  - `SLACK_CLIENT_SECRET`
  - `SLACK_VERIFICATION_TOKEN`
  - `STATE_KEY`
7. `foreman start -p 3000`
8. Create a Slack team and add SlashDeploy to it using the button on `http://localhost:3000`

### Tests

The full test suite can be run with:

```
$ ./bin/rake
```
