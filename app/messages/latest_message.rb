class LatestMessage < SlackMessage
  values do
    attribute :last_deployment, Deployment
  end

  def to_message
    fields = [
      {
        title: "Commit SHA",
        value: last_deployment.sha
      }
    ]

    Slack::Message.new text: text(last_deployment: last_deployment), attachments: [
      Slack::Attachment.new(
        color: '#3AA3E3',
        title: "#{last_deployment.repository}@#{last_deployment.ref}",
        title_link: "https://github.com/#{last_deployment.repository}/commit/#{last_deployment.sha}",
        fields: fields
      )
    ]
  end
end