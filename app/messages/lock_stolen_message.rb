class LockStolenMessage < SlackMessage
  values do
    attribute :environment, Environment
    attribute :thief, SlackAccount
  end

  def to_message
    Slack::Message.new text: text(thief: thief)
  end
end
