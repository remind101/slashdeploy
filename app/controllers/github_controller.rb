# GithubController handles the omniauth callback for GitHub.
class GithubController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def callback
    User.transaction do
      user.connected_accounts << slack_account  unless user.connected_account?(slack_account)
      user.connected_accounts << github_account unless user.connected_account?(github_account)
      warden.set_user user
    end
    redirect_to '/'
  end

  private

  def slack_account
    SlackAccount.new(
      foreign_id: slack_user['user_id'],
      username:   slack_user['user_name']
    )
  end

  def github_account
    GithubAccount.new(
      foreign_id: github_user['id'],
      username:   github_user['login'],
      token:      access_token.token
    )
  end

  def user
    @user ||= user_from_slack || user_from_github || User.create!
  end

  def user_from_github
    User.find_by_github_user_id(github_user['id'])
  end

  def user_from_slack
    User.find_by_slack_user_id(slack_user['user_id'])
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
