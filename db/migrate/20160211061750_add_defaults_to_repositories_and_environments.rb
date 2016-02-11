class AddDefaultsToRepositoriesAndEnvironments < ActiveRecord::Migration
  def change
    add_column :repositories, :default_environment, :string
    add_column :environments, :default_ref, :string
  end
end
