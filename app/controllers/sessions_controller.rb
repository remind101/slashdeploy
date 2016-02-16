class SessionsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    auth = request.env['omniauth.auth']
    auth.provider = 'slack' if auth.provider == 'slash'

    # Find an identity here
    @identity = Identity.find_or_create_with_omniauth(auth)

    if signed_in?
      if @identity.user == current_user
        # User is signed in so they are trying to link an identity with their
        # account. But we found the identity and the user associated with it 
        # is the current user. So the identity is already associated with 
        # this user. So let's display an error message.
        redirect_to root_url, notice: "Already linked that account!"
      else
        # The identity is not associated with the current_user so lets 
        # associate the identity
        @identity.user = current_user
        @identity.save
        redirect_to root_url, notice: "Successfully linked that account!"
      end
    else
      if @identity.user.present?
        # The identity we found had a user associated with it so let's 
        # just log them in here
        warden.set_user @identity.user
        redirect_to root_url, notice: "Signed in!"
      else
        @identity.user = User.new
        @identity.save
        # No user associated with the identity so we need to create a new one
        redirect_to root_url, notice: "Thanks for signing up!"
      end
    end
  end
end
