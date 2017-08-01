# Represents an "installation" of a GitHub app on an org/repository. This
# implements much of the same interface as User, since they sometimes are used
# interchangeably (e.g. when attributing a deployment to a GitHub user that
# SlashDeploy doesn't know about.
#
# See https://developer.github.com/apps/
class Installation < ActiveRecord::Base
  has_many :repositories

  def identifier
    'SlashDeploy'
  end

  def app
    SlashDeploy.github_app
  end

  def github_token
    app.installation_token(id).token
  end

  def octokit_client
    Octokit::Client.new(access_token: github_token)
  end

  def slack_account_for_github_organization(organization)
    # In theory, we could use the Slack Bot to send a message to a channel, but
    # for now, we don't do anything.
  end
end
