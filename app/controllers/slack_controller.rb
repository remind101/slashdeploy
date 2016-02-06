# SlackController handles the oauth callback for Slack.
class SlackController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def callback
    p access_token
    redirect_to installed_path
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
end
