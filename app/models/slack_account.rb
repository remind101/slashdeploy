# SlackAccount represents a connected Slack account.
class SlackAccount < ActiveRecord::Base
  PROVIDER = 'slack'

  belongs_to :user
  belongs_to :slack_team

  def self.find_or_create_with_omniauth(auth)
    find_with_omniauth(auth) || create_with_omniauth(auth)
  end

  def self.find_with_omniauth(auth)
    return unless auth.provider == PROVIDER
    find_by(id: auth.uid)
  end

  def self.create_with_omniauth(auth)
    return unless auth.provider == PROVIDER
    create!(
      id: auth.uid,
      user_name: auth.info.nickname,
      slack_team: SlackTeam.find_or_initialize_by(id: auth.info.team_id) do |team|
        team.domain = auth.info.team_domain
      end
    )
  end

  def team_id
    slack_team.id
  end

  def team_domain
    slack_team.domain
  end
end
