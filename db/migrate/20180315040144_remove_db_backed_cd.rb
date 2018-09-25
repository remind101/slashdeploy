class RemoveDbBackedCd < ActiveRecord::Migration
  def change
    remove_column :environments, :auto_deploy_ref
    remove_column :environments, :required_contexts
    remove_column :environments, :aliases
  end
end
