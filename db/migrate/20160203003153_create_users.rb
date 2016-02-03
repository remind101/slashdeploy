class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users, id: false do |t|
      t.string :id, null: false
      t.string :github_token, null: false

      t.timestamps null: false
    end
  end
end
