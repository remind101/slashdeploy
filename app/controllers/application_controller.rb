# The primary controller that all controllers inherit from.
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def current_user
    warden.user
  end
  helper_method :current_user

  def signed_in?
    warden.authenticated?
  end
  helper_method :signed_in?

  private

  def warden
    request.env['warden']
  end
end
