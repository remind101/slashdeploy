# SlackUser decorates a User under the context of a SlackTeam.
class SlackUser < SimpleDelegator
  attr_reader :slack_team

  def initialize(user, slack_team)
    super(user)
    @slack_team = slack_team
  end

  # Returns this users slack username under the given slack team.
  def slack_username
    account = user.slack_accounts.find { |a| a.team_id == slack_team.id }
    return unless account # TODO: Raise?
    account.user_name
  end

  # Returns the real User object.
  def user
    __getobj__
  end
end
