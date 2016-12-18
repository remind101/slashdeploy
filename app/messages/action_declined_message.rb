class ActionDeclinedMessage < SlackMessage
  values do
    attribute :declined_action_text, String
  end

  TEXT = "Did not <%= @declined_action_text %>."

  def to_message
    Slack::Message.new text: renderr(TEXT)
  end
end
