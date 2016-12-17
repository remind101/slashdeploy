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

## Contributing

Contributions are highly welcome! If you'd like to contribute, please read [CONTRIBUTING.md](./CONTRIBUTING.md)
