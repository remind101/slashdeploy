class LatestMessage < SlackMessage
  values do
    attribute :last_deployment, Deployment
    attribute :last_deployment_state, String
  end

  def to_message
    fields = [
      {
        title: "Commit SHA",
        value: last_deployment.sha[0..6],
        short: true
      },
      {
        title: "State",
        value: "`#{last_deployment_state}`",
        short: true
      }
    ]

    Slack::Message.new text: text(last_deployment: last_deployment), attachments: [
      Slack::Attachment.new(
        color: '#3AA3E3',
        title: "#{last_deployment.repository}@#{last_deployment.ref}",
        title_link: "https://github.com/#{last_deployment.repository}/commit/#{last_deployment.sha}",
        fields: fields,
        footer: "<https://github.com/#{last_deployment.repository}/deployments|Check all the latest deployments here>"
      )
    ]
  end
end