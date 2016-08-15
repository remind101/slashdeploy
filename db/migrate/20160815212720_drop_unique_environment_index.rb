class DropUniqueEnvironmentIndex < ActiveRecord::Migration
  def up
    execute 'DROP INDEX unique_auto_deployment_per_environment'
  end
  
  def down
    add_index :auto_deployments, [:environment_id], name: 'unique_auto_deployment_per_environment', unique: true, where: 'active'
  end
end
