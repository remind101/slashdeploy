module Slash
  # Action Registry
  class ActionRegistry
    attr_reader :registry

    def initialize
      @registry = {}
    end

    def register(action_name, action)
      registry[action_name] = action
    end

    def call(env)
      callback_id = env['action'].payload.callback_id
      message_action = MessageAction.find_by_callback_id(callback_id)
      action = registry[message_action.action]
      if action
        env['message_action'] = message_action
        action.call(env)
      else
        # not_found.call(env)
      end
    end
    
  end
end
