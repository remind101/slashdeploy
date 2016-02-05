# User represents a user of SlashDeploy.
class User < ActiveRecord::Base
  has_many :connected_accounts

  def self.find_by_slack_user_id(slack_user_id)
    account = SlackAccount.where(foreign_id: slack_user_id).first
    return unless account
    account.user
  end

  def slack_account
    connected_accounts.where(type: 'SlackAccount').first
  end
end
