# Represents a GitHub repository.
class Repository < ActiveRecord::Base
  has_many :environments
  validates :name, repository: true

  after_initialize do
    self.github_secret ||= SecureRandom.hex
  end

  # Finds the repository with the given name, creating it if necessary.
  def self.with_name(name)
    find_or_create_by(name: name)
  end

  # Finds the associated environment with the given name, creating it if
  # necessary. If name is nil, returns the default environment, if the
  # repository has a default environment set.
  def environment(name = nil)
    environments.with_name(name || default_environment)
  end

  # The default environment to deploy to when one is not specified.
  def default_environment
    super.presence
  end

  # Returns the environment that's configured to auto deploy this ref.
  # Returns nil if there is no environment configured for this branch.
  def auto_deploy_environment_for_ref(ref)
    environments.find { |env| env.auto_deploy?(ref) }
  end

  # Returns the organization portion of the repository name.
  def organization
    matches = SlashDeploy::GITHUB_REPO_REGEX.match(name)
    matches[1]
  end

  # Returns true if the repository is configured to deploy to the given target.
  def deploy_to?(target)
    case target.to_sym
    when :circleci
      circleci_api_token.present?
    else
      false
    end
  end

  def to_s
    name
  end
end
