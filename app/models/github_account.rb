# GithubAccount represents a connected GitHub account.
class GithubAccount < ActiveRecord::Base
  belongs_to :user
end
