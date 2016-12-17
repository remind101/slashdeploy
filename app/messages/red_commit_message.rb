class RedCommitMessage < SlackMessage
  values do
    attribute :contexts, Array[CommitStatusContext]
    attribute :message_action, MessageAction
  end

  def to_message
    Slack::Message.new text: text, attachments: [
      Slack::Attachment.new(
        title: 'Ignore status checks and deploy anyway?',
        callback_id: message_action.callback_id,
        color: '#3AA3E3',
        actions: SlackMessage.confirmation_actions
      )
    ]
  end
end
