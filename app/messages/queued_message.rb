class QueuedMessage < SlackMessage
  values do
    attribute :environment, Environment
    attribute :position, Fixnum
  end

  def to_message
    Slack::Message.new text: text
  end
end
