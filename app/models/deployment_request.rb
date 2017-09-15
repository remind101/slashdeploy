# A DeploymentRequest represents the options provided when requesting a new deployment.
DeploymentRequest = Struct.new(:repository, :ref, :environment, :force) do
  def initialize(opts = {})
    super \
      opts[:repository],
      opts[:ref],
      opts[:environment],
      opts[:force]
  end
end
