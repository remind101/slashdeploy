class AutoDeploymentFailedMessage < SlackMessage
  values do
    attribute :account, SlackAccount
    attribute :status, Status
    attribute :auto_deployment, AutoDeployment
  end

  def to_message
    Slack::Message.new text: text, attachments: [
      Slack::Attachment.new(
        mrkdwn_in: ['text'],
        title: status.context,
        title_link: status.target_url,
        text: status.description,
        color: '#F00'
      )
    ]
  end
end
