class AutoDeploymentFailedMessage < SlackMessage
  values do
    attribute :account, SlackAccount
    attribute :status, Status
    attribute :auto_deployment, AutoDeployment
  end

  def to_message
    Slack::Message.new attachments: [
      Slack::Attachment.new(
        mrkdwn_in: ['text'],
        text: text,
        color: '#F00'
      )
    ]
  end
end
