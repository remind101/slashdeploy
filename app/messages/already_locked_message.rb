class AlreadyLockedMessage < SlackMessage
  TEXT = "*<%= @environment %>* is already locked"

  values do
    attribute :environment, Environment
  end

  def to_message
    Slack::Message.new text: renderr(TEXT)
  end
end
