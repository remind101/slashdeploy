class AddGithubSecretToRepositories < ActiveRecord::Migration
  def up
    add_column :repositories, :github_secret, :string
    Repository.reset_column_information
    Repository.find_each do |repository|
      repository.update_attributes!(github_secret: SecureRandom.hex)
    end
    change_column :repositories, :github_secret, :string, null: false
  end
  
  def down
    remove_column :repositories, :github_secret
  end
end
