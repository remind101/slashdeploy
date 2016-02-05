class CreateConnectedAccounts < ActiveRecord::Migration
  def change
    execute 'DELETE FROM locks WHERE 1 = 1'

    remove_foreign_key :locks, :users
    drop_table :users
    create_table :users do |t|
      t.timestamps null: false
    end
    remove_column :locks, :user_id
    add_column :locks, :user_id, :integer, null: false
    add_foreign_key :locks, :users

    create_table :connected_accounts do |t|
      t.integer :user_id, null: false
      t.string :foreign_id, null: false
      t.string :type, null: false
      t.string :token
      t.string :username

      t.timestamps null: false
    end

    add_index :connected_accounts, :type
    add_index :connected_accounts, :user_id
    add_index :connected_accounts, [:type, :foreign_id], unique: true
    add_foreign_key :connected_accounts, :users
  end
end
