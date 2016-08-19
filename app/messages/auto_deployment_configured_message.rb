class AutoDeploymentConfiguredMessage < SlackMessage
  values do
    attribute :environment, Environment
    attribute :message_action, MessageAction
  end

  def to_message
    Slack::Message.new text: text, attachments: [
      Slack::Attachment.new(
        title: 'Ignore and deploy anyway?',
        callback_id: message_action.callback_id,
        color: '#3AA3E3',
        actions: SlackMessage.confirmation_actions
      )
    ]
  end
end
