# Represents a GitHub repository.
class Repository < ActiveRecord::Base
  has_many :environments

  # Finds the repository with the given name, creating it if necessary.
  def self.with_name(name)
    find_or_create_by(name: name)
  end

  # Finds the associated environment with the given name, creating it if necessary.
  def environment(name)
    environments.with_name(name)
  end
end
