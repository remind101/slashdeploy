# User represents a user of SlashDeploy.
class User < ActiveRecord::Base
  has_many :connected_accounts

  def self.find_by_slack_user_id(slack_user_id)
    account = SlackAccount.where(foreign_id: slack_user_id).first
    return unless account
    account.user
  end

  def self.find_by_github_user_id(github_user_id)
    account = GithubAccount.where(foreign_id: github_user_id).first
    return unless account
    account.user
  end

  def connected_account?(connected_account)
    connected_accounts.find do |account|
      account.type == connected_account.type &&
        account.foreign_id == connected_account.foreign_id
    end
  end
end
