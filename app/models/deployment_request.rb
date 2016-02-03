# A DeploymentRequest represents the options provided when requesting a new deployment.
class DeploymentRequest
  include Virtus.value_object

  values do
    # The repository to deploy.
    attribute :repository, String
    # The git branch, tag or commit to deploy.
    attribute :ref, String
    # The environment to deploy to.
    attribute :environment, String
    # Whether to "force" the deployment or not (i.e. Ignore commit status contexts).
    attribute :force, Boolean
  end

  def to_s
    s = "#{repository}"
    s = "#{s}@#{ref}" if ref
    s = "#{s} to #{environment}" if environment
    s
  end
end
