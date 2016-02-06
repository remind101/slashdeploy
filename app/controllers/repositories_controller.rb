class RepositoriesController < ApplicationController
  def show
    @repository = Repository.find_by!(name: "#{params[:owner]}/#{params[:repo]}")
  end
end
