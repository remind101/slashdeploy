class CreateAutoDeployments < ActiveRecord::Migration
  def change
    create_table :auto_deployments do |t|
      t.references :user, index: true, foreign_key: true, null: false
      t.references :environment, index: true, foreign_key: true, null: false
      t.string :sha, null: false, index: true
      t.boolean :active, null: false, default: true

      t.timestamps null: false
    end

    add_index :auto_deployments, [:environment_id, :sha], unique: true

    # Ensure that we never have more than 1 active auto deployment per environment.
    add_index :auto_deployments, [:environment_id], name: 'unique_auto_deployment_per_environment', unique: true, where: 'active'

    create_table :statuses do |t|
      t.string :sha, index: true, null: false
      t.string :context, null: false
      t.string :state, null: false
    end
  end
end
