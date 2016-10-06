class PassedLockMessage < SlackMessage
  values do
    attribute :environment, Environment
    attribute :new_active_lock, Lock
  end

  def to_message
    Slack::Message.new text: text(receiver: receiver)
  end

  def receiver
    user = slack_user(new_active_lock.user) if new_active_lock
    user
  end
end
