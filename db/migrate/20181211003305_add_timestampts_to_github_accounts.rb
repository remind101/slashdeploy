class AddTimestamptsToGitHubAccounts < ActiveRecord::Migration
  def change
    add_timestamps :github_accounts, null: true
  end
end
