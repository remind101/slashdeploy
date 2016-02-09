class AddInChannelToEnvironments < ActiveRecord::Migration
  def up
    add_column :environments, :in_channel, :boolean, null: false, default: false
    execute <<-SQL
    UPDATE environments SET in_channel = 't' WHERE name = 'production'
    SQL
  end
  
  def down
    remove_column :environments, :in_channel
  end
end
