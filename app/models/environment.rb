# Environment represents a known environment that a repository can be deployed to.
class Environment < ActiveRecord::Base
  has_many :locks
  belongs_to :repository
  belongs_to :auto_deploy_user, class_name: :User, foreign_key: :auto_deploy_user_id

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
    super((aliases || []).select { |a| a != name })
  end

  # Configures this environment to auto deploy the given branch.
  def configure_auto_deploy(branch, options = {})
    self.update_attributes!(auto_deploy_branch: branch, auto_deploy_user: options[:user])
  end

  def auto_deploy?(branch)
    auto_deploy_branch == branch
  end

  # The default git ref to deploy when none is provided for this environment.
  def default_ref
    super.presence || self.class.default_ref
  end

  def self.default_ref
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
