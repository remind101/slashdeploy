class ConnectedAccount
  def self.from_auth_hash(auth_hash)
    klass = case auth_hash[:provider]
            when 'github'
              GitHubAccount
            when 'slack'
              SlackAccount
            end
    fail "Cannot create connected account for #{auth_hash[:provider]}" unless klass
    fail 'Auth has does not specify a UID' unless auth_hash[:uid]
    account = klass.find_by(id: auth_hash[:uid])
    if account
      # Update the account to ensure that we have the most recent username,
      # access token, etc.
      account.update_from_auth_hash(auth_hash)
    else
      klass.create_from_auth_hash(auth_hash)
    end
  end
end
