class RemoveNotNullConstraintFromUserIdOnAutodeployments < ActiveRecord::Migration
  def change
    change_column :auto_deployments, :user_id, :integer, :null => true
  end
end
