class UnlockedMessage < SlackMessage
  # the models.environment::Environment to unlock
  values do
    attribute :environment, Environment
  end

  def to_message
    Slack::Message.new text: text
  end
end
