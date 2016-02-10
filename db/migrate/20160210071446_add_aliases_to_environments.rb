class AddAliasesToEnvironments < ActiveRecord::Migration
  def change
    add_column :environments, :aliases, :text, array: true, default: []
    add_index :environments, [:repository_id, :name], unique: true
  end
end
