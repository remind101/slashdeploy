# SlackController handles the oauth callback for Slack.
class SlackController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def callback
    access_token
    redirect_to installed_path
  end

  def install
    redirect_to client.auth_code.authorize_url(scope: 'bot,commands') unless beta?
  end

  def early_access
    EarlyAccess.create(email: params[:email])
  end

  def installed
  end

  private

  def access_token
    @access_token ||= client.auth_code.get_token(params[:code])
  end

  def client
    Rails.configuration.x.oauth.slack
  end

  def beta?
    Rails.configuration.x.beta
  end
end
