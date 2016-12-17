# SlackUser decorates a User under the context of a SlackTeam.
class SlackUser < SimpleDelegator
  attr_reader :slack_team

  def initialize(user, slack_team)
    super(user)
    @slack_team = slack_team
  end

  # Returns this users slack username under the given slack team.
  def slack_username
    return unless slack_account
    slack_account.user_name
  end

  def slack_userid
    return unless slack_account
    slack_account.id
  end

  # Returns the real User object.
  def user
    __getobj__
  end

  private

  def slack_account
    @slack_account ||= user.slack_accounts.find { |a| a.team_id == slack_team.id }
  end
end
