class CreateSlackBots < ActiveRecord::Migration
  def change
    create_table :slack_bots, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.string :slack_team_id, null: false
      t.string :access_token, null: false

      t.timestamps null: false
    end
    
    add_index :slack_bots, :slack_team_id, unique: true
  end
end
