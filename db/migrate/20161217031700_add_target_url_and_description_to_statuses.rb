class AddTargetUrlAndDescriptionToStatuses < ActiveRecord::Migration
  def change
    add_column :statuses, :target_url, :text
    add_column :statuses, :description, :text
  end
end
