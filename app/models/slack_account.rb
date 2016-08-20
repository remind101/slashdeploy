# SlackAccount represents a connected Slack account.
class SlackAccount < ActiveRecord::Base
  belongs_to :user
  belongs_to :slack_team

  def github_organization
    slack_team.github_organization
  end

  def self.attributes_from_auth_hash(auth_hash)
    { id: auth_hash[:uid],
      user_name: auth_hash[:info][:nickname] }
  end

  def self.create_from_auth_hash(auth_hash)
    team = SlackTeam.find_or_initialize_by(id: auth_hash[:info][:team_id]) do |t|
      t.domain = auth_hash[:info][:team_domain]
    end

    create! attributes_from_auth_hash(auth_hash).merge(slack_team: team)
  end

  def update_from_auth_hash(auth_hash)
    update_attributes! self.class.attributes_from_auth_hash(auth_hash).except(:id)
    self
  end

  def self.find_or_create_from_command_payload(payload)
    find_by_id(payload.user_id) || create_from_command_payload(payload)
  end

  def self.create_from_command_payload(payload)
    team = SlackTeam.find_or_initialize_by(id: payload.team_id) do |t|
      t.domain = payload.team_domain
    end

    create! \
      id:         payload.user_id,
      user_name:  payload.user_name,
      slack_team: team
  end

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
