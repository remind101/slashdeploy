# SlackController handles the oauth callback for Slack.
class SlackController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def callback
    if access_token['bot']
      SlackBot.find_or_create_by(id: access_token['bot']['bot_user_id']) do |slack_bot|
        slack_bot.access_token = access_token['bot']['bot_access_token']
        slack_bot.slack_team_id = access_token['team_id']
      end
    end
    redirect_to installed_path
  end

  def install
    redirect_to client.auth_code.authorize_url(scope: 'bot,commands') unless beta?
  end

  def early_access
    EarlyAccess.create(email: params[:email])
    $statsd.event 'New signup', "New signup from #{params[:email]} @slack-slashdeploy"
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
