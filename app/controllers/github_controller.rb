# GithubController handles the omniauth callback for GitHub.
class GithubController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def callback
    User.transaction do
      user.slack_accounts << slack_account unless user.slack_account?(slack_account)
      user.github_accounts << github_account unless user.github_account?(github_account)
      warden.set_user user
    end
    redirect_to '/'
  end

  private

  def slack_account
    SlackAccount.new(
      id:          slack_user['user_id'],
      user_name:   slack_user['user_name'],
      team_id:     slack_user['team_id'],
      team_domain: slack_user['team_domain']
    )
  end

  def github_account
    GithubAccount.new(
      id:    github_user['id'],
      login: github_user['login'],
      token: access_token.token
    )
  end

  def user
    @user ||= user_from_slack || user_from_github || User.create!
  end

  def user_from_github
    User.find_by_github(github_user['id'])
  end

  def user_from_slack
    User.find_by_slack(slack_user['user_id'])
  end

  def slack_user
    @slack_user ||= state_decoder.decode(params[:state])
  end

  def github_user
    @github_user ||= access_token.get('/user').parsed
  end

  def client
    Rails.configuration.x.oauth.github
  end

  def access_token
    @access_token ||= client.auth_code.get_token(params[:code])
  end

  def state_decoder
    SlashDeploy.state
  end
end
