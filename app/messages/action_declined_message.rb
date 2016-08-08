class ActionDeclinedMessage < SlackMessage
  values do
    attribute :declined_action_text, String
  end

  def to_message
    Slack::Message.new text: text
  end
end
