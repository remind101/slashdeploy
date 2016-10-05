class AlreadyQueuedMessage < SlackMessage
  values do
    attribute :environment, Environment
  end

  def to_message
    Slack::Message.new text: text
  end
end
