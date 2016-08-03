# User represents a user of SlashDeploy.
class User < ActiveRecord::Base
  has_many :github_accounts
  has_many :slack_accounts
  has_many :auto_deployments

  # Raised if the user doesn't have a github account.
  MissingGitHubAccount = Class.new(StandardError)

  def enable_slack_notifications!
    update_attributes! slack_notifications: true
  end

  def identifier
    "#{id}:#{username}"
  end

  def connected_accounts
    github_accounts + slack_accounts
  end

  def username
    if account = github_accounts.first
      return account.login
    end

    if account = slack_accounts.first
      return account.user_name
    end
  end

  def self.find_by_slack(id)
    account = SlackAccount.find_by(id: id)
    account.user if account
  end

  def self.find_by_github(id)
    account = GitHubAccount.find_by(id: id)
    account.user if account
  end

  def github_account
    github_accounts.first || fail(MissingGitHubAccount)
  end

  def github_token
    account = github_account
    return unless account
    account.token
  end

  def github_login
    account = github_account
    return unless account
    account.login
  end

  def octokit_client
    @client ||= Octokit::Client.new(access_token: github_token)
  end
end
