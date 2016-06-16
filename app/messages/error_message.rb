class ErrorMessage < SlackMessage
  def to_message
    Slack::Message text: text
  end
end
