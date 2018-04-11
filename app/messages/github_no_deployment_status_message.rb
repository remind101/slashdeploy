class GithubNoDeploymentStatusMessage < SlackMessage
  values do
    attribute :account, SlackAccount
    attribute :github_deployment, Deployment
  end

  def to_message
    Slack::Message.new text: text
  end
end
