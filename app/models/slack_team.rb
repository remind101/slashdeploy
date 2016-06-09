class SlackTeam < ActiveRecord::Base
  has_many :slack_accounts
  has_one :slack_bot
end
