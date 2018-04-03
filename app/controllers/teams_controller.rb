class TeamsController < ApplicationController
  before_action :authenticate!
  def index
    @slack_teams = current_user.slack_teams
    # get a list of slack team objects who have slack_accounts with locks.
    # @slack_teams_with_locks = current_user.slack_teams.includes(
    #   slack_accounts: [:locks]
    # )
  end
end
