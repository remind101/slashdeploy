class AutoDeploymentFailedMessage < SlackMessage
  values do
    attribute :account, SlackAccount
    attribute :auto_deployment, AutoDeployment
  end

  def to_message
    attachments = auto_deployment.failing_statuses.map do |status|
      Slack::Attachment.new(
        mrkdwn_in: ['text'],
        title: status.context,
        title_link: status.target_url,
        text: status.description,
        color: '#F00'
      )
    end
    # Let them know that they can fix the build and we'll still deploy.
    attachments << Slack::Attachment.new(
      mrkdwn_in: ['pretext'],
      pretext: render(:rebuild)
    )
    Slack::Message.new text: text, attachments: attachments
  end
end
