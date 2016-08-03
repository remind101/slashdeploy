class SessionsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def failure
    render text: 'Authentication failed'
  end

  def create
    auth_hash = request.env['omniauth.auth']

    SlackBot.find_or_create_from_auth_hash(auth_hash) if auth_hash[:provider] == 'slack' && auth_hash[:extra][:bot_info].present?

    User.transaction do
      account = ConnectedAccount.find_or_create_from_auth_hash(auth_hash)

      if signed_in?
        if account.user == current_user
          # User is signed in so they are trying to link an identity with their
          # account. But we found the identity and the user associated with it 
          # is the current user. So the identity is already associated with 
          # this user. So let's display an error message.
          redirect_to root_url, notice: "Already linked that account!"
        else
          # The identity is not associated with the current_user so lets 
          # associate the identity.
          account.user = current_user
          account.save!
          redirect_to root_url, notice: "Successfully linked that account!"
        end
      else
        if account.user.present?
          # The identity we found had a user associated with it so let's 
          # just log them in here.
          warden.set_user account.user
          redirect_to root_url, notice: "Signed in!"
        else
          # No user associated with the identity so sign them up.
          user = User.new
          account.user = user
          account.save!
          warden.set_user user
          redirect_to root_url, notice: "Signed up!"
        end
      end
    end
  end
end
