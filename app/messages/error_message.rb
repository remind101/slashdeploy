class ErrorMessage < SlackMessage
  def to_message
    Slack::Message.new text: text
  end
end
