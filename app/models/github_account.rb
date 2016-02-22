# GitHubAccount represents a connected GitHub account.
class GitHubAccount < ActiveRecord::Base
  belongs_to :user
end
