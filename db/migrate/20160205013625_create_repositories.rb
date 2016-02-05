class CreateRepositories < ActiveRecord::Migration
  def change
    create_table :repositories do |t|
      t.string :name, unique: true, null: false

      t.timestamps null: false
    end

    add_column :environments, :repository_id, :integer

    execute <<-SQL
      INSERT INTO repositories (name, created_at, updated_at) SELECT repository, now(), now() FROM environments GROUP BY repository;
    SQL
    execute <<-SQL
      UPDATE environments AS e SET repository_id = r.id FROM repositories AS r WHERE r.name = e.repository;
    SQL

    change_column :environments, :repository_id, :integer, null: false
    add_foreign_key :environments, :repositories
    remove_column :environments, :repository
  end
end
