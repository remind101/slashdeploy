# SlackController handles the oauth callback for Slack.
class SlackController < ApplicationController
  skip_before_filter :verify_authenticity_token

  skip_before_action :authenticate!

  def install
    redirect_to oauth_path(:slack, scope: 'bot,commands') unless beta?
  end

  def early_access
    EarlyAccess.create(email: params[:email])
    $statsd.event 'New signup', "New signup from #{params[:email]} @slack-slashdeploy"
  end

  def installed
  end

  private

  def beta?
    Rails.configuration.x.beta
  end
end
