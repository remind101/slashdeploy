class PingMessage < SlackMessage
  def to_message
    Slack::Message.new text: 'Ping'
  end
end
