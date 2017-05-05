# UnlockAction handles the response from the unlock command buttons
class UnlockAction < BaseAction
  def run
    transaction do
      env.merge!('params' => message_action.action_params.to_h)
      if action.value == 'yes'
        UnlockCommand.call(env)
      else
        Slash.reply ActionDeclinedMessage.build \
          declined_action_text: 'unlock'
      end
    end
  end
end
