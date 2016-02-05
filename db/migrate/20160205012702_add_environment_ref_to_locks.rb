class AddEnvironmentRefToLocks < ActiveRecord::Migration
  def change
    change_column :locks, :environment_id, :integer, null: false
    add_foreign_key :locks, :environments
  end
end
