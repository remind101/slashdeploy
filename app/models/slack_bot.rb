class SlackBot < ActiveRecord::Base
  belongs_to :slack_team

  def self.from_auth_hash(auth_hash)
    bot_info = auth_hash[:extra][:bot_info]
    bot = find_by(id: bot_info.fetch(:bot_access_token))
    if bot
      bot.update_attributes(access_token: bot_info.fetch(:bot_access_token))
    else
      create(id: bot_info[:bot_access_token]) do |bot|
        bot.access_token = bot_info[:bot_access_token]
        bot.slack_team_id = auth_hash[:info][:team_id]
      end
    end
  end
end
