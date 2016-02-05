class CreateConnectedAccounts < ActiveRecord::Migration
  def up
    execute 'DELETE FROM locks WHERE 1 = 1'

    remove_foreign_key :locks, :users
    drop_table :users
    create_table :users do |t|
      t.timestamps null: false
    end
    remove_column :locks, :user_id
    add_column :locks, :user_id, :integer, null: false
    add_foreign_key :locks, :users

    create_table :github_accounts, id: false do |t|
      t.integer :user_id
      t.integer :id, null: false, primary_key: true
      t.string :login, null: false
      t.string :token, null: false
    end

    add_index :github_accounts, :id, unique: true
    add_foreign_key :github_accounts, :users

    create_table :slack_accounts, id: false do |t|
      t.integer :user_id
      t.string :id, null: false, primary_key: true
      t.string :user_name, null: false
      t.string :team_id, null: false
      t.string :team_domain, null: false
    end

    add_index :slack_accounts, :id, unique: true
    add_foreign_key :slack_accounts, :users
  end

  def down
    drop_table :github_accounts
    drop_table :slack_accounts

    remove_foreign_key :locks, :users
    drop_table :users
    create_table :users, id: false do |t|
      t.string :id, null: false
      t.string :github_token, null: false

      t.timestamps null: false
    end
    add_index :users, :id, unique: true
    remove_column :locks, :user_id
    add_column :locks, :user_id, :string, null: false
    add_foreign_key :locks, :users
  end
end
