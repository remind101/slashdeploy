class AutoDeploymentStartedMessage < SlackMessage
  values do
    attribute :account, SlackAccount
    attribute :auto_deployment, AutoDeployment
  end

  def to_message
    Slack::Message.new text: text
  end
end
