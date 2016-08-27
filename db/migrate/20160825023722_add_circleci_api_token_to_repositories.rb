class AddCircleciApiTokenToRepositories < ActiveRecord::Migration
  def change
    add_column :repositories, :circleci_api_token, :string
  end
end
