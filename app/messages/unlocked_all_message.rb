class UnlockedAllMessage < SlackMessage

  # list of Environment objects that will be unlocked.
  values do
    attribute :environments, Array[Environment]
  end

  def to_message
    Slack::Message.new text: text
  end
end
