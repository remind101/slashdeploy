# UnlockAllAction handles the response from the "unlock all" buttons.
class UnlockAllAction < BaseAction
  def run
    transaction do
      env.merge!('params' => message_action.action_params.to_h)
      if action.value == 'yes'
        UnlockAllCommand.call(env)
      else
        Slash.reply ActionDeclinedMessage.build \
          declined_action_text: 'unlock'
      end
    end
  end
end
