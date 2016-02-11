class AddAutoDeployBranchToEnvironment < ActiveRecord::Migration
  def change
    add_column :environments, :auto_deploy_ref, :string
    add_column :environments, :auto_deploy_user_id, :integer
  end
end
