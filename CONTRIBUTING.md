## Environment Setup

SlashDeploy uses a `Gemfile` to document dependencies.

The following external dependencies are also required:

 * `Postgresql 9.6`
 * `Ruby 2.5.1` (optionally `rbenv`)
 * `bundler`

### macOS

1. install [brew](https://brew.sh/)
1. install `PostgreSQL 9`: `brew install postgresql@9.6`
1. start `PostgreSQL 9` : `brew services start postgresql@9.6`
1. install `rbenv`: `brew install rbenv`
1. install `bundler`: `gem install bundler`

### Linux

1. TODO

## Install SlashDeploy

1. clone `slashdeploy`: `git clone git@github.com:remind101/slashdeploy.git`
1. change dir to project root: `cd slashdeploy`
1. install `slashdeploy`: `bundle install`
1. create database schema: `bundle exec rake db:setup`
1. migrate database schema: `bundle exec rake db:migrate`

## Docker

You can also use Docker for development and testing:

```
make test
```

## Tests

The full test suite can be run with:

```
./bin/rake
```

## Development

### Using ngrok

1. Install [ngrok](https://ngrok.com/) and run `./ngrok http 3000`

### Setup a new Slack App

1. Create a [Slack App](https://api.slack.com/apps/new)
1. Set your Interactive Components Request URL to
   `https://xxx.ngrok.io/slack/actions`
1. Add a new OAuth & Permissions Redirect URL with the value
   `https://xxx.ngrok.io/auth/slack/callback`
1. Add a new `/deploy` command by setting the Request URL to
   `https://xxx.ngrok.io/slack/commands`

### Setup a new Github OAuth App

1. Register a new [Github OAuth
   Application](https://github.com/settings/applications/new)
1. Set your Github Authorization callback URL to
   `http://xxx.ngrok.io/auth/github/callback`

### Start the Development server

1. Using Slack and Github app credentials, set the following environment
   variables in a `.env` file:

```
STATE_KEY=""

# the ngrok.io URI.
URL="https://xxx.ngrok.io"

# find these on the Github OAuth App's Developer settings page.
GITHUB_CLIENT="github"
GITHUB_CLIENT_ID=""
GITHUB_CLIENT_SECRET=""

# find these on the Slack App's Basic Information tab.
SLACK_CLIENT="slack"
SLACK_CLIENT_ID=""
SLACK_CLIENT_SECRET=""
SLACK_VERIFICATION_TOKEN=""
```

2. `foreman start -p 3000`

### Functional Tests

1. Create a Slack team and add SlashDeploy to it using the button on
   `https://xxx.ngrok.io`
