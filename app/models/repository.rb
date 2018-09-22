# Represents a GitHub repository.
class Repository < ActiveRecord::Base
  belongs_to :installation
  has_many :environments
  validates :name, repository: true

  after_initialize do
    self.github_secret ||= SecureRandom.hex
  end

  # Finds the repository with the given name, creating it if necessary.
  def self.with_name(name)
    find_or_create_by(name: name)
  end

  # Get or create associated environment with the given name.
  # If given name is nil, return the default environment if configured.
  # If default environment is not configured, this method will return nil.
  def environment(name = nil)
    name = default_environment_name unless name
    known_environments.find { |env| env.match_name?(name) }
  end

  # Returns a list of known environments for this repository. If the repository
  # has a config present, that controls what environments are known.
  def known_environments
    return [] unless config?
    config.environments.map { |name, _| environments.find_or_create_by(name: name) }
  end

  # The default environment name if configured.
  def default_environment_name
    return nil unless config?
    config.default_environment
  end

  # The default environment name if configured.
  def default_environment
    return nil unless default_environment_name
    environment(default_environment_name)
  end

  # Returns the environment that's configured to auto deploy this ref.
  # Returns nil if there is no environment configured for this branch.
  def auto_deploy_environments_for_ref(ref)
    known_environments.select { |env| env.auto_deploy?(ref) }
  end

  # Returns the organization portion of the repository name.
  def organization
    matches = SlashDeploy::GITHUB_REPO_REGEX.match(name)
    matches[1]
  end

  # Returns the slack account that should be used when DM'ing the user about
  # this repository.
  def slack_account_for(user)
    user.slack_account_for_github_organization(organization)
  end

  def configure!(raw_config)
    update_column :raw_config, raw_config
  end

  # Returns true if this repository has a .slashdeploy.yml file, and if we
  # should use it for configuration.
  def config?
    raw_config.present?
  end

  # Returns a Ruby representation of the raw config.
  def config
    fail(SlashDeploy::NoConfig) unless config?
    SlashDeploy::Config.from_yaml(raw_config)
  end

  def to_s
    name
  end
end
