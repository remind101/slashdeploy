class DeploymentCreatedMessage < SlackMessage
  values do
    attribute :deployment, Deployment
    attribute :last_deployment, Deployment
  end

  def to_message
    Slack::Message.new text: text(diff_url: diff_url)
  end

  private

  # Returns a url with a diff between the old and new deployment.
  def diff_url
    return unless last_deployment
    return if deployment.sha == last_deployment.sha
    "https://github.com/#{deployment.repository}/compare/#{last_deployment.sha[0..6]}...#{deployment.sha[0..6]}"
  end
end
