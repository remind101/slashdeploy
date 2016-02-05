# GithubController handles the omniauth callback for GitHub.
class GithubController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def callback
    t = access_token
    user = User.find_by_slack_user_id(slack_user['user_id'])
    unless user
      User.transaction do
        user = User.create!
        user.connected_accounts << SlackAccount.new(
          foreign_id: slack_user['user_id'],
          username:   slack_user['user_name']
        )
        user.connected_accounts << GithubAccount.new(
          foreign_id: github_user['id'],
          username:   github_user['login'],
          token:      t.token
        )
      end
    end
    warden.set_user user
    redirect_to '/'
  end

  private

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
