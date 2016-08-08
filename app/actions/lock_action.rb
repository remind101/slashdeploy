
class LockAction < BaseAction
  def run
    transaction do
      env.merge!('params' => message_action.action_params.to_h)
      if action.value == 'yes'
        LockCommand.call(env)
      else
        Slash.reply ActionDeclinedMessage.build \
          declined_action: 'steal lock'
      end
    end
  end
end
