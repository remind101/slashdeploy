class CheckMessage < SlackMessage
  values do
    attribute :environment, Environment
    attribute :lock, Lock
  end

  def to_message
    Slack::Message.new attachments: [Slack::Attachment.new(text: lock_message)]
  end

  private

  def lock_message
    text(locker: locker)
  end

  def locker
    slack_user lock.try(:user)
  end
end
