class GitHubDeploymentStatusMessage < SlackMessage
  STATUSES = {
    'pending'  => ['#ff0', 'started'],
    'success'  => ['#0f0', 'succeeded'],
    'failure'  => ['#f00', 'failed'],
    'error'    => ['#f00', 'errored'],
    'inactive' => ['#0f0', 'superseded'],
  }.freeze

  values do
    attribute :account, SlackAccount
    attribute :event, Hash
  end

  def to_message
    state = event['deployment_status']['state']
    description = event['deployment_status']['description']

    # hack: for some reason a GitHub Deployment Status in the inactive state
    # does not trigger a webhook. To work around this, we piggy back on the
    # success state and add the real state as the description.
    if state == "success" && description == "inactive"
        state = "inactive"
        description = ""
    end

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
