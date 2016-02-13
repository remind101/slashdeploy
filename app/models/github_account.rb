# GithubAccount represents a connected GitHub account.
class GithubAccount < ActiveRecord::Base
  PROVIDER = 'github'

  belongs_to :user

  def self.find_with_omniauth(auth)
    return unless auth.provider == PROVIDER
    find_by(id: auth.uid)
  end

  def self.create_with_omniauth(auth)
    return unless auth.provider == PROVIDER
    create(id: auth.uid, login: auth.info.nickname, token: auth.credentials.token)
  end
end
