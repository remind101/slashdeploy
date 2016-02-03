# Environment represents a known environment that a repository can be deployed to.
class Environment < ActiveRecord::Base
  has_many :locks

  # Marks the environment as "used" (e.g. someone just triggered a deployment to it).
  def self.used(repository, environment)
    Environment.find_or_create_by(repository: repository, name: environment)
  end

  # Marks this environment as locked with the given message.
  def lock!(message)
    locks.create(message: message, active: true)
  end
end
