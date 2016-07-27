class EnableSlackNotifications < ActiveRecord::Migration
  def change
    change_column_default(:users, :slack_notifications, true)

    execute <<-SQL
    UPDATE users SET slack_notifications = 't'
    SQL
  end
end
