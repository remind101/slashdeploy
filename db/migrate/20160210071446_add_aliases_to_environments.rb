class AddAliasesToEnvironments < ActiveRecord::Migration
  def change
    add_column :environments, :aliases, :text, array: true, default: []
    add_index :environments, [:repository_id, :name], unique: true
    execute <<-SQL
    UPDATE environments SET aliases = (CASE name
      WHEN 'production' THEN '{"prod"}'::text[]
      WHEN 'staging' THEN '{"stage"}'::text[]
      END);
    SQL
  end

  def down
    drop_column :environments, :aliases
  end
end
