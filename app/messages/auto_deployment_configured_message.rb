class AutoDeploymentConfiguredMessage < SlackMessage
  values do
    attribute :environment, Environment
    attribute :command_payload, Slash::CommandPayload
  end

  def to_message
    Slack::Message.new text: text
  end
end
