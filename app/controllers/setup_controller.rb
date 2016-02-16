class SetupController < ApplicationController
  def show
    return redirect_to "/auth/slash?origin=#{setup_path}&account=#{params['account']}" if params['account']
    return redirect_to '/auth/github' if signed_in? && !current_user.github_account?
    redirect_to root_url
  end
end
