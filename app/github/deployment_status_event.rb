# Handles the deployment_status event from github.
class DeploymentStatusEvent < GitHubEventHandler
  def run
    return logger.info('no matching github user') unless user
    return logger.info('user does not have slack notifications enabled') unless user.slack_notifications?
    logger.info(event)
    slashdeploy.direct_message \
      user.slack_account_for_github_organization(organization),
      GitHubDeploymentStatusMessage,
      event: event
  end

  private

  def organization
    event['repository']['owner']['login']
  end

  def user
    @user ||= User.find_by_github(event['deployment']['creator']['id'])
  end
end
