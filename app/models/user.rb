# User represents a user of SlashDeploy.
class User < ActiveRecord::Base
  has_many :github_accounts
  has_many :slack_accounts
  has_many :auto_deployments

  # Raised if the user doesn't have a github account.
  MissingGitHubAccount = Class.new(StandardError)

  def username
    github_account.login
  end

  def self.find_by_slack(id)
    account = SlackAccount.where(id: id).first
    return unless account
    account.user
  end

  def self.find_by_github(id)
    account = GithubAccount.where(id: id).first
    return unless account
    account.user
  end

  def slack_account?(slack_account)
    slack_accounts.find do |account|
      account.id == slack_account.id
    end
  end

  def github_account?(github_account)
    github_accounts.find do |account|
      account.id == github_account.id
    end
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
