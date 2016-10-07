class EnvironmentLockedMessage < SlackMessage
  values do
    attribute :environment, Environment
    attribute :lock, Lock
    attribute :message_action, MessageAction
  end

  def to_message
    Slack::Message.new text: text(locker: locker), attachments: [
      Slack::Attachment.new(
        title: self.class.attachment_title,
        callback_id: message_action.callback_id,
        color: '#3AA3E3',
        actions: self.class.confirmation_actions
      )
    ]
  end

  private

  def locker
    slack_user lock.user
  end

  def self.attachment_title
    'Steal or queue up for the lock?'
  end

  # has an option to queue
  def self.confirmation_actions
    [
      Slack::Attachment::Action.new(
        name: 'yes',
        text: 'Yes',
        type: 'button',
        style: 'primary',
        value: 'yes'),
      Slack::Attachment::Action.new(
        name: 'queue',
        text: 'Queue',
        type: 'button',
        value: 'queue'),
      Slack::Attachment::Action.new(
        name: 'no',
        text: 'No',
        type: 'button',
        value: 'no')
    ]
  end
end
