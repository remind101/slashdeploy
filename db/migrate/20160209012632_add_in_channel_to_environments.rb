class AddInChannelToEnvironments < ActiveRecord::Migration
  def change
    add_column :environments, :in_channel, :boolean, null: false, default: false
    execute <<-SQL
    UPDATE environments SET in_channel = 't' WHERE name = 'production'
    SQL
  end
end
