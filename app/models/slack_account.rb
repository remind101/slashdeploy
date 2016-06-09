# SlackAccount represents a connected Slack account.
class SlackAccount < ActiveRecord::Base
  belongs_to :user
  belongs_to :slack_team

  def team_id
    slack_team.id
  end

  def team_domain
    slack_team.domain
  end

  def bot_access_token
    slack_team.bot_access_token
  end
end
