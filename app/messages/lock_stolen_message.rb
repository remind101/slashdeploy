class LockStolenMessage < SlackMessage
  values do
    attribute :environment, Environment
    attribute :thief, User
  end

  def to_message
    Slack::Message.new text: text(thief_account: thief_account)
  end

  def thief_account
    slack_account(thief) if thief
  end
end
