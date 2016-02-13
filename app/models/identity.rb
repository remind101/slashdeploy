# Identity represents a third party identity.
class Identity
  PROVIDERS = [GithubAccount, SlackAccount]

  def self.find_with_omniauth(auth)
    PROVIDERS.find do |provider|
      ident = provider.find_with_omniauth(auth)
      return ident if ident
    end
  end

  def self.create_with_omniauth(auth)
    PROVIDERS.each do |provider|
      ident = provider.create_with_omniauth(auth)
      return ident if ident
    end
  end

  def self.find_or_create_with_omniauth(auth)
    find_with_omniauth(auth) || create_with_omniauth(auth)
  end
end
