class LockedMessage < SlackMessage
  values do
    attribute :environment, Environment
    attribute :stolen_lock, Lock
  end

  def to_message
    Slack::Message.new text: text(stealer: stealer)
  end

  private

  def stealer
    slack_user(stolen_lock.user) if stolen_lock
  end
end
