# SlashActions is a slash handler that provides SlashDeploy slack slash
# actions. This class routes whitelisted action names to the appropriate
# action.
class SlashActions
  attr_reader :registry

  def self.registry
    registry = Slash::ActionRegistry.new
    registry.register 'LockAction', LockAction
    registry.register 'DeployAction', DeployAction

    registry
  end

  def self.build
    new registry
  end

  def initialize(registry)
    @registry = registry
  end

  def call(env)
    user = env['user']

    scope = {
      person: { id: user.id, username: user.username }
    }

    Rollbar.scoped(scope) do
      begin
        registry.call(env)
      rescue SlashDeploy::RepoUnauthorized => e
        Slash.reply UnauthorizedMessage.build \
          repository: e.repository
      rescue StandardError => e
        Rollbar.error(e)
        raise e if Rails.env.test?
        Slash.reply ErrorMessage.build
      end
    end
  end
end
