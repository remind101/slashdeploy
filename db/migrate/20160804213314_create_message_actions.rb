class CreateMessageActions < ActiveRecord::Migration
  def change
    create_table :message_actions, id: false do |t|
      t.uuid :callback_id, null: false
      t.json :action_params
      t.string :action, null: false

      t.timestamps null: false
    end

    add_index :message_actions, :callback_id
  end
end
