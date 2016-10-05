# LockAction handles the response from the lock command buttons
class LockAction < BaseAction
  def run
    transaction do
      env.merge!('params' => message_action.action_params.to_h)
      case action.value
      when 'yes'
        LockCommand.call(env)
      when 'queue'
        QueueCommand.call(env)
      else
        Slash.reply ActionDeclinedMessage.build \
          declined_action_text: 'steal lock'
      end
    end
  end
end
