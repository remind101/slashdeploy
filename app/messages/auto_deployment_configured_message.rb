class AutoDeploymentConfiguredMessage < SlackMessage
  values do
    attribute :environment, Environment
    attribute :request, Slash::Request
  end

  def to_message
    Slack::Message.new text: text
  end
end
