class ConnectedAccount
  def self.find_or_create_from_auth_hash(auth_hash)
    klass = case auth_hash[:provider]
            when 'github'
              GitHubAccount
            when 'slack'
              SlackAccount
            end
    raise "Cannot create connected account for #{auth_hash[:provider]}" unless klass
    klass.find_by(id: auth_hash[:uid]) || klass.create_from_auth_hash(auth_hash)
  end
end
