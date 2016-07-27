class AddSlackNotificationsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :slack_notifications, :boolean
  end
end
