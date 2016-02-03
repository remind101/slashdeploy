# GithubController handles the omniauth callback for GitHub.
class GithubController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def callback
    t = access_token
    user = User.find_or_create_by(id: user_id) do |u|
      u.github_token = t.token
    end
    warden.set_user user
    redirect_to '/'
  end

  private

  def user_id
    data = state_decoder.decode(params[:state])
    data['user_id']
  end

  def client
    Rails.configuration.x.oauth.github
  end

  def access_token
    client.auth_code.get_token(params[:code])
  end

  def state_decoder
    SlashDeploy.state
  end
end
