class RepositoriesController < ApplicationController
  def edit
    @repository = Repository.find_by!(name: params[:id])
  end

  def update
    @repository = Repository.find_by!(name: params[:id])
    @repository.default_environment = params[:repository][:default_environment]
    if @repository.save
      redirect_to repository_edit_path(@repository)
    else
      render :edit
    end
  end
end
