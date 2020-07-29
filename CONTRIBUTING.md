## Environment Setup

SlashDeploy uses a `Gemfile` to document dependencies.

The following external dependencies are also required:

 * `Postgresql 9.6`
 * `Redis`
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


## Tests

The full test suite can be run with:

```sh
./bin/rake
```

## Docker

You can also use Docker for development and testing:

```sh
make dev  # run the whole stack containerized
make test # run the test suite
```

Read on for more details about how to set up a full dev environment below.

## Development

The basic process is to set up a Slack app and GitHub app which you will need to
authenticate with in order to facilitate communication between them. Because
you're setting this up locally, you need a way for Slack and GitHub to reach
your development server, which is achieved via Ngrok. Ngrok will open a reverse
proxy connection to an Ngrok server, which will proxy traffic back to your local
machine over a secure tunnel. This both provides a publicly routable address
that services like GitHub, Slack and users can reach, and also provides valid
TLS encryption for the connection, all the way back to your local server
(provided you trust Ngrok, since they're essentially performing
[MITM](https://en.wikipedia.org/wiki/Man-in-the-middle_attack) on your traffic).

### Start Ngrok

**IMPORTANT!** Ngrok will provide you with both an HTTP and HTTPS URL; make sure
you're using the HTTPS version everywhere.

1. Install [ngrok](https://ngrok.com/) if you don't already have it. Put it
   somewhere in your `PATH`.
1. Run `make ngrok`. This will start proxying traffic to localhost:3000.

### Set up `.env`

1. Create an `.env` file in the root of the repository. This file will be
ignored via `.gitignore`, and is for storing credentials/secrets for your
development instance. Start with:

```sh
STATE_KEY=""

# the ngrok.io URI. Make sure this is HTTPS!
URL="https://xxx.ngrok.io"
```

You'll continue adding configuration to this file as we proceed.

### Create a Slack App

1. Create a [New Slack Workspace](https://slack.com/get-started#/create). **This
   is important!** If you install the app we're about to create in an
   existing/production workspace, you'll conflict with the existing SlashDeploy
   installation, and expose your dev environment to everyone in the workspace.
   Additionally, **you must create the workspace and be signed into the new
   workspace when you create the Slack app**. Slack will not allow you to
   install the app to another workspace without publishing it.
1. Create a [Slack App](https://api.slack.com/apps/new)
1. Select 'Slash Commands' from the left sidebar, under the 'Features' heading
   1. Select '**Create New Command**'
   1. Enter the following information:
      Command | /deploy
      Request URL | `https://xxx.ngrok.io/slack/commands`
      Short Description | SlashDeploy`your name`
      Usage Hint | Whatever you like
      Escape channels, users, and links sent to your app | unchecked
   1. **Important!** Make sure to click 'Save' down in the lower right
1. Select 'OAuth & Permissions' from the left sidebar, under the 'Features'
   heading
   1. Select the 'Add New Redirect URL' button under the 'Redirect URLs' section
   1. Set the **Redirect URL** to `https://xxx.ngrok.io/auth/slack/callback`
   1. Click the 'Add' button
   1. Click the 'Save' button
1. Select 'Interactivity & Shortcuts' from the left sidebar, under the
   'Features' heading
   1. Turn the feature on with the toggle button
   1. Set the **Interactivity Request URL** to `https://xxx.ngrok.io/slack/actions`
   1. **Important!** Make sure to click 'Save' down in the lower right
1. Select 'Install App' from the left sidebar, under the 'Settings' heading
    1. Click the 'Install App to Workspace' and add the app to your workspace of
       choice. Remember, you can only install an app to the workspace specified
       when you created it.
1. Select 'Basic Information' from the left sidebar under the 'Settings' heading
   1. Set the following variables in your `.env` file:
      ```sh
      SLACK_CLIENT="slack"
      SLACK_CLIENT_ID="<Client ID>"
      SLACK_CLIENT_SECRET="<Client Secret>"
      SLACK_VERIFICATION_TOKEN="<Verification Token>"
      ```

### Create a Github OAuth App

1. Register a new [Github OAuth
   Application](https://github.com/settings/applications/new), using the
   following config:
   Application name | Same as the name of your Slack app
   Homepage URL | `https://xxx.ngrok.io`
   Application description | Whatever you want
   Authorization callback URL | `https://xxx.ngrok.io/auth/github/callback`
1. Click 'Create' button
1. The next screen should have the integration config. Set the following
   variables in your `.env` file:
   ```sh
   GITHUB_CLIENT="github"
   GITHUB_CLIENT_ID="<Client ID>"
   GITHUB_CLIENT_SECRET="<Client Secret>"
   ```

### Start the Development server

You can run the development server locally:

* `foreman start -p 3000`

Or use Docker:

* make dev

### Visit the App

1. You can now visit `https://xxx.ngrok.io` and connect the app. The first time
   you attempt to use the `/deploy` command from your test Slack workspace,
   you'll be asked to authenticate with GitHub.

