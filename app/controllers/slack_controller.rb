# SlackController handles the oauth callback for Slack.
class SlackController < ApplicationController
  def install
    redirect_to '/auth/slack' unless beta?
  end

  def early_access
    EarlyAccess.create(email: params[:email])
  end

  def installed
  end

  private

  def beta?
    Rails.configuration.x.beta
  end
end
