## Tests

The full test suite can be run with:

```
$ ./bin/rake db:setup
$ ./bin/rake
```

## Development

SlashDeploy requires PostgreSQL; you can install it through Homebrew on OSX and `apt-get` on Linux.

### Using ngrok

1. Install [ngrok](https://ngrok.com/) and run `./ngrok http 3000`
2. Create a [Slack App](https://api.slack.com/apps/new), set your Slack Redirect URI to `http://xxx.ngrok.io/auth/slack/callback` and set your Interactive Messages Request URL to `https://xxx.ngrok.io/slack/actions`
3. Listen to `/deploy` commands by setting the Request URL to `https://xxx.ngrok.io/slack/commands`
4. Register a new [Github OAuth application](https://github.com/settings/applications/new)
5. Set your Github Authorization callback URL to `http://xxx.ngrok.io/auth/github/callback`
6. Using Slack and Github app credentials, set the following environment variables in a `.env` file:
  - `GITHUB_CLIENT` (set to `github` to use the actual client, a fake one is set otherwise)
  - `SLACK_CLIENT` (set to `slack` to use the actual client, a fake one is set otherwise)
  - `GITHUB_CLIENT_ID`
  - `GITHUB_CLIENT_SECRET`
  - `SLACK_CLIENT_ID`
  - `SLACK_CLIENT_SECRET`
  - `SLACK_VERIFICATION_TOKEN`
  - `STATE_KEY`
7. `foreman start -p 3000`
8. Create a Slack team and add SlashDeploy to it using the button on `http://localhost:3000`
