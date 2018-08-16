class UnlockedAllMessage < SlackMessage

  # list of Lock objects that were unlocked.
  values do
    attribute :locks, Array[Lock]
  end

  def to_message
    Slack::Message.new text: text
  end
end
