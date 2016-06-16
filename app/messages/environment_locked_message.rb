class EnvironmentLockedMessage < SlackMessage
  values do
    attribute :environment, Environment
    attribute :lock, Lock
    attribute :request, Slash::Request
  end

  def to_message
    Slack::Message.new text: text(locker: locker)
  end

  private

  def locker
    slack_user lock.user
  end
end
