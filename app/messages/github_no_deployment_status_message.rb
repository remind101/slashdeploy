class GitHubNoDeploymentStatusMessage < SlackMessage
  values do
    attribute :account, SlackAccount
  end

  def to_message
    Slack::Message.new text: text
  end
end
