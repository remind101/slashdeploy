# Environment represents a known environment that a repository can be deployed to.
class Environment < ActiveRecord::Base
  has_many :locks
  belongs_to :repository

  # Validate that an alias doesn't match a different environment.
  validates_with UniqueEnvironment

  # Scopes environments to find those that either have the given name, or are
  # aliased.
  scope :named, -> (value) do
    name    = arel_table[:name]
    aliases = arel_table[:aliases]
    where(name.eq(value).or(aliases.contains([value])))
  end

  # Set defaults.
  after_initialize do
    # Default to in_channel responses when the environment looks like a
    # production environment.
    self.in_channel ||= true if name == 'production'
  end

  # Finds the environment with the given name, creating it if necessary.
  def self.with_name(name)
    named(name).first || create!(name: name)
  end

  # Marks this environment as locked with the given message.
  def lock!(user, message = nil)
    locks.active.create!(user: user, message: message)
  end

  # Returns the currently active lock for this environment, or nil if there is none.
  def active_lock
    locks.active.first
  end

  # Override the aliases setter to filter out aliases that match the name of
  # the environment.
  def aliases=(aliases)
    super(aliases.select { |a| a != name })
  end

  # The default git ref to deploy when none is provided for this environment.
  def default_ref
    Rails.configuration.x.default_ref
  end

  # Returns other environments for the repository matching the given name.
  def other_environments_named(name)
    repository.environments
      .where.not(id: id)
      .named(name)
  end

  def to_s
    name
  end
end
