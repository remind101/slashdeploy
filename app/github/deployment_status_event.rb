# Handles the deployment_status event from github.
class DeploymentStatusEvent < GitHubEventHandler
  def run
    return logger.info('no matching github user') unless user
    return logger.info('user does not have slack notifications enabled') unless user.slack_notifications?

    # log the deployment status event.
    state = event['deployment_status']['state']
    state_desc = event['deployment_status']['description']
    deployment_id = event['deployment']['id']
    environment_name = event['deployment']['environment']
    github_user_name = event['deployment']['creator']['login']
    repo_name = event['repository']['full_name']
    logger.info("Deployment: id=#{deployment_id}, state=#{state}, desc=#{state_desc}, environment=#{environment_name}, repo=#{repo_name}, gitub_user=#{github_user_name}")
    # end of logging the deployment status event.

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
