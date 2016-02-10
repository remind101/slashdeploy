class AddAliasesToEnvironments < ActiveRecord::Migration
  def change
    add_column :environments, :aliases, :text, array: true, default: []
  end
end
