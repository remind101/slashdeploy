class SessionsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def failure
    render text: 'Authentication failed'
  end

  def destroy
    warden.logout
    redirect_to root_path
  end

  def jwt
    user = User.find(auth_hash[:uid])
    warden.set_user user
    if user.github_accounts.empty?
      redirect_to oauth_path(:github)
    else
      redirect_to after_sign_in_path
    end
  end

  def create
    SlackBot.from_auth_hash(auth_hash) if auth_hash[:provider] == 'slack' && auth_hash[:extra][:bot_info].present?

    User.transaction do
      account = ConnectedAccount.from_auth_hash(auth_hash)

      if signed_in?
        if account.user == current_user
          # User is signed in so they are trying to link an identity with their
          # account. But we found the identity and the user associated with it
          # is the current user. So the identity is already associated with
          # this user. So let's display an error message.
          redirect_to after_sign_in_path, flash: { warning: "You've already linked that account!" }
        else
          # The identity is not associated with the current_user so lets
          # associate the identity.
          account.user = current_user
          account.save!
          redirect_to after_sign_in_path, flash: { success: 'Successfully linked that account!' }
        end
      else
        if account.user.present?
          # The identity we found had a user associated with it so let's
          # just log them in here.
          sign_in_and_redirect account.user
        else
          # No user associated with the identity so sign them up.
          user = User.new
          account.user = user
          account.save!
          sign_in_and_redirect user, flash: { success: 'Thanks for signing up!' }
        end
      end
    end
  end

  private

  def auth_hash
    request.env['omniauth.auth']
  end

  def after_sign_in_path
    request.env['omniauth.origin'] || root_url
  end

  def sign_in_and_redirect(user, *args)
    warden.set_user user
    redirect_to after_sign_in_path, *args
  end
end
