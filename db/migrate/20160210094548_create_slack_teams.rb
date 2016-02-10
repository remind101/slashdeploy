class CreateSlackTeams < ActiveRecord::Migration
  def up
    create_table :slack_teams, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.string :domain, null: false
      t.string :github_organization

      t.timestamps null: false
    end

    execute <<-SQL
    INSERT INTO slack_teams (id, domain, created_at, updated_at) SELECT team_id, team_domain, now(), now() FROM slack_accounts GROUP BY team_id, team_domain
    SQL

    rename_column :slack_accounts, :team_id, :slack_team_id
    add_index :slack_teams, :id, unique: true
    add_foreign_key :slack_accounts, :slack_teams
    remove_column :slack_accounts, :team_domain
  end

  def down
    add_column :slack_accounts, :team_domain, :string

    execute <<-SQL
    UPDATE slack_accounts sa SET team_domain = st.domain FROM slack_teams st WHERE sa.slack_team_id = st.id
    SQL

    change_column :slack_accounts, :team_domain, :string, null: false

    remove_foreign_key :slack_accounts, :slack_teams
    drop_table :slack_teams
    rename_column :slack_accounts, :slack_team_id, :team_id
  end
end
