class AddUserIdToLocks < ActiveRecord::Migration
  def change
    execute 'DELETE FROM locks WHERE 1 = 1'

    add_index :users, :id, unique: true

    change_table :locks do |t|
      t.string :user_id, null: false, unique: true
    end

    add_foreign_key :locks, :users
  end
end
