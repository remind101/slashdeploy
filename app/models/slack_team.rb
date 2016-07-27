class SlackTeam < ActiveRecord::Base
  has_many :slack_accounts
  has_one :slack_bot

  def bot
    slack_bot || fail("Team #{id} does not have a slack bot")
  end

  def bot_access_token
    bot.access_token
  end
end
