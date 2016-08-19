class EnvironmentLockedMessage < SlackMessage
  values do
    attribute :environment, Environment
    attribute :lock, Lock
    attribute :message_action, MessageAction
    attribute :command_payload, Slash::CommandPayload
  end

  def to_message
    Slack::Message.new text: text(locker: locker), attachments: [
      Slack::Attachment.new(
        title: 'Steal the lock?',
        callback_id: message_action.callback_id,
        color: '#3AA3E3',
        actions: confirmation_actions
      )
    ]
  end

  private

  def locker
    slack_user lock.user
  end
end
