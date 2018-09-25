# Environment represents a known environment that a repository can be deployed to.
class Environment < ActiveRecord::Base
  has_many :locks
  has_many :auto_deployments
  belongs_to :repository
  belongs_to :auto_deploy_user, class_name: :User, foreign_key: :auto_deploy_user_id

  validates :name, presence: true, uniqueness: { scope: :repository_id }

  # TODO(ejholmes): Pending migration: https://github.com/remind101/slashdeploy/blob/ba259375fa8b7c845d36eda6f545643ccaad643b/db/migrate/20180315040144_remove_db_backed_cd.rb
  def self.columns
    removed = ["auto_deploy_ref", "required_contexts", "aliases"]
    super.reject { |c| removed.include?(c.name) }
  end

  # Set defaults.
  after_initialize do
    # Default to in_channel responses when the environment looks like a
    # production environment.
    self.in_channel ||= true if name == 'production'
  end

  # Marks this environment as locked with the given message.
  def lock!(user, message = nil)
    locks.active.create!(user: user, message: message)
  end

  # Returns the currently active lock for this environment, or nil if there is none.
  def active_lock
    locks.active.first
  end

  def locked_by?(user)
    locked? && active_lock.user == user
  end

  # Returns true if this environment is locked.
  def locked?
    active_lock.present?
  end

  # Returns true if the provided name, matches the canonical environment name,
  # or one of it's aliases.
  def match_name?(name)
    return true if self.name == name
    return true if config.aliases.include?(name)
    false
  end

  # Returns the aliases for this environment.
  def aliases
    config.aliases
  end

  # Checks if this environment is configured to automatically deploy the given ref.
  def auto_deploy?(ref)
    auto_deploy_ref == ref
  end

  # Returns the ref that should trigger CD to this environment.
  def auto_deploy_ref
    continuous_delivery_config? ? config.continuous_delivery.ref : nil
  end

  # Returns the required commit status contexts for CD to this environment.
  def required_contexts
    continuous_delivery_config? ? config.continuous_delivery.required_contexts : nil
  end

  # Returns true if this environment is configured to automatically deploy.
  def auto_deploy_enabled?
    auto_deploy_ref.present?
  end

  # The default git ref to deploy when none is provided for this environment.
  def default_ref
    super.presence || self.class.default_ref
  end

  def self.default_ref
    Rails.configuration.x.default_ref
  end

  # Returns the slack account that should be used when DM'ing the user about
  # this environment.
  def slack_account_for(user)
    repository.slack_account_for(user)
  end

  def installation
    repository.installation
  end

  def config?
    config.present?
  end

  def continuous_delivery_config?
    config? && config.continuous_delivery.present?
  end

  def config
    return unless repository && repository.config?
    repository.config.environments[name]
  end

  def to_s
    name
  end
end
