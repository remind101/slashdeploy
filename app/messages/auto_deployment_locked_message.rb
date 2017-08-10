class AutoDeploymentLockedMessage < SlackMessage
  values do
    attribute :account, SlackAccount
    attribute :auto_deployment, Environment
    attribute :lock, Lock
  end

  def to_message
    Slack::Message.new text: text(locker: locker, environment: auto_deployment.environment)
  end

  private

  def locker
    slack_account lock.user
  end

  def slack_team
    account.slack_team
  end
end
