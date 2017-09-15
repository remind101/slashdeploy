# A DeploymentRequest represents the options provided when requesting a new GitHub deployment.
DeploymentRequest = Struct.new(:repository, :ref, :environment, :required_contexts) do
  def initialize(opts = {})
    super \
      opts[:repository],
      opts[:ref],
      opts[:environment],
      opts[:required_contexts]
  end

  def force?
    required_contexts == []
  end
end
