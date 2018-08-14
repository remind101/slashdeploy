# User represents a user of SlashDeploy.
class User < ActiveRecord::Base
  has_many :github_accounts
  has_many :slack_accounts
  has_many :slack_teams, through: :slack_accounts
  has_many :auto_deployments
  has_many :locks

  # Raised if the user doesn't have a github account.
  MissingGitHubAccount = Class.new(StandardError)

  def enable_slack_notifications!
    update_attributes! slack_notifications: true
  end

  def identifier
    "#{id}:#{username}"
  end

  # Unlock all active locks.
  def unlock_all!
    locks.map(&:unlock!)
  end

  # username determine by the following priority:
  # 1. GithubAccount#username, 2. SlackAccount#username, 3. User#id
  def username
    account = github_accounts.first || slack_accounts.first
    account ? account.username : id
  end

  # class method to lookup a User object by Slack id.
  def self.find_by_slack(id)
    account = SlackAccount.where(id: id).first
    return unless account
    account.user
  end

  # class method to lookup a User object by Github id.
  def self.find_by_github(id)
    account = GitHubAccount.where(id: id).first
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

  # Returns the SlackAccount that should be used when sending direct messages
  # related to the GitHub organization.
  #
  # Returns nil if no matching account is found.
  def slack_account_for_github_organization(organization)
    slack_accounts.find { |account| account.github_organization == organization }
  end
end
