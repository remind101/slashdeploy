class DeploymentCreatedMessage < SlackMessage
  values do
    attribute :environment, Environment
    attribute :deployment, Deployment
    attribute :last_deployment, Deployment

    # Present if we should ask the user if they want to lock the environment.
    attribute :lock_action, MessageAction

    # Present if we should ask the user if they want to unlock the environment.
    attribute :unlock_action, MessageAction
  end

  def to_message
    attachments = []

    if lock_action
      attachments << Slack::Attachment.new(
        mrkdwn_in: ['text'],
        title: "Lock #{environment}?",
        text: "The default ref for *#{environment}* is `#{environment.default_ref}`, but you deployed `#{deployment.ref}`.",
        callback_id: lock_action.callback_id,
        color: '#3AA3E3',
        actions: SlackMessage.confirmation_actions
      )
    end

    if unlock_action
      attachments << Slack::Attachment.new(
        mrkdwn_in: ['text'],
        title: "Unlock #{environment}?",
        text: "You just deployed the default ref for *#{environment}*. Do you want to unlock it?",
        callback_id: unlock_action.callback_id,
        color: '#3AA3E3',
        actions: SlackMessage.confirmation_actions
      )
    end

    Slack::Message.new text: text(diff_url: diff_url), attachments: attachments
  end

  private

  # Returns a url with a diff between the old and new deployment.
  def diff_url
    return unless last_deployment
    return if deployment.sha == last_deployment.sha
    "https://github.com/#{deployment.repository}/compare/#{last_deployment.sha[0..6]}...#{deployment.sha[0..6]}"
  end
end
