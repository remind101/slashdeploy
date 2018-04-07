# GitHubAccount represents a connected GitHub account.
class GitHubAccount < ActiveRecord::Base
  belongs_to :user

  def self.attributes_from_auth_hash(auth_hash)
    { id: auth_hash[:uid],
      login: auth_hash[:info][:nickname],
      token: auth_hash[:credentials][:token] }
  end

  def self.create_from_auth_hash(auth_hash)
    create! attributes_from_auth_hash(auth_hash)
  end

  def update_from_auth_hash(auth_hash)
    update_attributes! self.class.attributes_from_auth_hash(auth_hash).except(:id)
    self
  end

  def username
    login
  end
end
