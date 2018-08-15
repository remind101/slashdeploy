class UnlockedAllMessage < SlackMessage

  # list of lock objects that will be unlocked.
  values do
    attribute :locks, Array
  end

  def to_message
    Slack::Message.new text: text
  end
end
