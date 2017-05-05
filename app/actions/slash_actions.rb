# SlashActions is a slash handler that provides SlashDeploy slack slash
# actions. This class routes whitelisted action names to the appropriate
# action.
class SlashActions
  ACTIONS = [
    LockAction,
    UnlockAction,
    DeployAction
  ]

  attr_reader :actions

  def self.build
    actions = ACTIONS.each_with_object({}) { |klass, h| h[klass.name] = klass }
    new actions
  end

  def initialize(actions)
    @actions = actions
  end

  def call(env)
    user = env['user']

    scope = {
      person: { id: user.id, username: user.username }
    }

    Rollbar.scoped(scope) do
      begin
        callback_id = env['action'].payload.callback_id
        message_action = MessageAction.find_by_callback_id(callback_id)
        if message_action
          action = actions[message_action.action]
          if action
            env['message_action'] = message_action
            action.call(env)
          else
            Slash.reply ErrorMessage.build
          end
        else
          Slash.reply ErrorMessage.build
        end
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
