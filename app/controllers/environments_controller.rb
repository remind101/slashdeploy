class EnvironmentsController < ApplicationController
  def edit
    @repository = Repository.find_by!(name: params[:repository_id])
    @environment = @repository.environments.find_by!(name: params[:id])
  end

  def update
    @repository = Repository.find_by!(name: params[:repository_id])
    @environment = @repository.environments.find_by!(name: params[:id])

    @environment.default_ref = params[:environment][:default_ref]
    @environment.auto_deploy_ref = params[:environment][:auto_deploy_ref]

    if @environment.save
      redirect_to repository_environment_edit_path(@repository, @environment)
    else
      render :edit
    end
  end
end
