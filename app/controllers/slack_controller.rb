class SlackController < ApplicationController
  def install
    redirect_to '/auth/slack?scope=bot,commands'
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
