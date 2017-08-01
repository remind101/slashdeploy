class CreateInstallations < ActiveRecord::Migration
  def up
    create_table :installations, id: false do |t|
      t.integer :id, null: false, primary_key: true

      t.timestamps null: false
    end

    add_column :repositories, :installation_id, :integer
    change_column :auto_deployments, :user_id, :integer, null: true

    add_index :installations, :id, unique: true
  end

  def down
    drop_table :installations
    remove_column :repositories, :installation_id
    change_column :auto_deployments, :user_id, :integer, null: false
  end
end
