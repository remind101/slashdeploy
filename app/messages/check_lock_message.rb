class CheckLockMessage < SlackMessage
  values do
    attribute :environment, Environment
    attribute :lock, Lock
  end

  def to_message
    Slack::Message.new text: text(locker: locker)
  end

  private

  def locker
    slack_user lock.try(:user)
  end
end
