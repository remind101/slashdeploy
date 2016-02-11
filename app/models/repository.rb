# Represents a GitHub repository.
class Repository < ActiveRecord::Base
  has_many :environments
  validates :name, repository: true

  # Finds the repository with the given name, creating it if necessary.
  def self.with_name(name)
    find_or_create_by!(name: name)
  end

  # Finds the associated environment with the given name, creating it if
  # necessary. If name is nil, returns the default environment.
  def environment(name = nil)
    environments.with_name(name || default_environment)
  end

  # The default environment to deploy to when one is not specified.
  def default_environment
    super.presence || self.class.default_environment
  end

  # The name of the default environment for a repository.
  def self.default_environment
    Rails.configuration.x.default_environment
  end

  def to_s
    name
  end
end
