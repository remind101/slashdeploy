module Slash
  # Action Registry contains a whitelist of valid action_names and their corresponding action.
  class ActionRegistry
    attr_reader :registry

    def initialize
      @registry = {}
    end

    def register(action_name, action)
      registry[action_name] = action
    end

    # Find the MessageAction from the callback_id and store in env
    # Call if action is whitelisted
    def call(env)
      callback_id = env['action'].payload.callback_id
      message_action = MessageAction.find_by_callback_id(callback_id)
      action = registry[message_action.action]
      if action
        env['message_action'] = message_action
        action.call(env)
      else
        Slash.reply ErrorMessage.build
      end
    end
  end
end
