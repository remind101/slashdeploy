class DeployAction < BaseAction
  def run
    transaction do
      env.merge!('params' => message_action.action_params.to_h)
      if action.value == 'yes'
        DeployCommand.call(env)
      else
        Slash.reply ActionDeclinedMessage.build \
          declined_action_text: 'deploy'
      end
    end
  end
end
