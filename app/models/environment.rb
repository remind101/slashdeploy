# Environment represents a known environment that a repository can be deployed to.
class Environment < ActiveRecord::Base
  has_many :locks
  belongs_to :repository

  # Finds the environment with the given name, creating it if necessary.
  def self.with_name(name)
    find_or_create_by(name: name)
  end

  # Marks this environment as locked with the given message.
  def lock!(user, message = nil)
    locks.active.create!(user: user, message: message)
  end

  # Returns the currently active lock for this environment, or nil if there is none.
  def active_lock
    locks.active.first
  end
end
