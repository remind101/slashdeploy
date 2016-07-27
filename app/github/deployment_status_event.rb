# Handles the deployment_status event from github.
class DeploymentStatusEvent < GitHubEventHandler
  def run
    return logger.info('no matching github user') unless user
    return logger.info('user does not have slack notifications enabled') unless user.slack_notifications?
    slashdeploy.direct_message \
      user,
      GitHubDeploymentStatusMessage,
      event: event
  end

  private

  def user
    @user ||= User.find_by_github_account_id(event['deployment']['creator']['id'])
  end
end
