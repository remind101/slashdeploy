class LockNagMessage < SlackMessage
  values do
    attribute :lock, Lock
    attribute :account, SlackAccount
    attribute :message_action, MessageAction
  end

  def to_message
    Slack::Message.new text: text(locker: locker), attachments: [
      Slack::Attachment.new(
        title: 'Unlock?',
        callback_id: message_action.callback_id,
        color: '#3AA3E3',
        actions: SlackMessage.confirmation_actions
      )
    ]
  end

  private

  def locker
    lock.slack_account
  end
end
