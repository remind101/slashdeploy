class CheckMessage < SlackMessage
  values do
    attribute :environment, Environment
  end

  def to_message
    lock_status = Slack::Attachment.new(
      mrkdwn_in: ['text'],
      title: 'Lock Status',
      text: lock_message,
      color: environment.locked? ? '#F00' : '#3AA3E3'
    )
    Slack::Message.new text: "#{environment.repository.name} (*#{environment.name}*)", attachments: [lock_status]
  end

  private

  def lock_message
    text(locker: locker, lock: lock)
  end

  def locker
    return unless lock
    slack_account lock.user
  end

  def lock
    environment.active_lock
  end
end
