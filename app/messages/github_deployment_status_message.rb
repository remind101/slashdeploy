class GitHubDeploymentStatusMessage < SlackMessage
  STATUSES = {
    'pending' => ['#ff0', 'started'],
    'success' => ['#0f0', 'succeeded'],
    'failure' => ['#f00', 'failed'],
    'error'   => ['#f00', 'errored']
  }.freeze

  values do
    attribute :account, SlackAccount
    attribute :event, Hash
  end

  def to_message
    state = event['deployment_status']['state']
    color, verb = STATUSES[state]
    Slack::Message.new attachments: [
      Slack::Attachment.new(
        color: color,
        mrkdwn_in: ['text'],
        text: text(verb: verb),
        fallback: "Deployment #{verb}"
      )
    ]
  end
end
