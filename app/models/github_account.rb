# GitHubAccount represents a connected GitHub account.
class GitHubAccount < ActiveRecord::Base
  belongs_to :user

  def self.create_from_auth_hash(auth_hash)
    create!(
      id: auth_hash[:uid],
      login: auth_hash[:info][:nickname],
      token: auth_hash[:credentials][:token]
    )
  end

  def connect_to(user)
    user.github_accounts << self
  end
end
