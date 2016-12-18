class AutoDeploymentConfiguredMessage < SlackMessage
  TEXT = "<%= @environment.repository %> is configured to automatically deploy `<%= @environment.auto_deploy_ref %>` to *<%= @environment %>*."

  values do
    attribute :environment, Environment
    attribute :message_action, MessageAction
  end

  def to_message
    Slack::Message.new text: renderr(TEXT), attachments: [
      Slack::Attachment.new(
        title: 'Deploy anyway?',
        callback_id: message_action.callback_id,
        color: '#3AA3E3',
        actions: SlackMessage.confirmation_actions
      )
    ]
  end
end
