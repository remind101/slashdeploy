# Environment represents a known environment that a repository can be deployed to.
class Environment < ActiveRecord::Base
  # Marks the environment as "used" (e.g. someone just triggered a deployment to it).
  def self.used(repository, environment)
    Environment.find_or_create_by(repository: repository, name: environment)
  end
end
