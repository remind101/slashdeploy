class AutoDeploymentFailedMessage < SlackMessage
  values do
    attribute :account, SlackAccount
    attribute :status, Status
    attribute :auto_deployment, AutoDeployment
  end

  def to_message
    Slack::Message.new text: text
  end
end
