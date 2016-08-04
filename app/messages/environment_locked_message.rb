class EnvironmentLockedMessage < SlackMessage
  values do
    attribute :environment, Environment
    attribute :lock, Lock
    attribute :message_action, MessageAction
    attribute :request, Slash::Request
  end

  def to_message
    Slack::Message.new text: text(locker: locker), attachments: [
      Slack::Attachment.new(
        mrkdwn_in: ['text'],
        callback_id: message_action.callback_id,
        color: '#3AA3E3',
        actions: [
          Slack::Attachment::Action.new(
            name: "yes",
            text: "Yes",
            type: "button",
            style: "primary",
            value: "yes"),
          Slack::Attachment::Action.new(
            name: "no",
            text: "No",
            type: "button",
            value: "no")
        ]
      )
    ]
  end

  private

  def locker
    slack_user lock.user
  end
end
