class AutoDeploymentFailedMessage < SlackMessage
  values do
    attribute :account, SlackAccount
    attribute :auto_deployment, AutoDeployment
    attribute :commit_status_context, CommitStatusContext
  end

  def to_message
    Slack::Message.new text: text
  end
end
