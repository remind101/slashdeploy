class GithubDeploymentWatchdogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deployment_watchdog'

  # default time to wait until our worker wakes up.
  DEFAULT_DELAY = 30.seconds

  # create a class method to hardcode how we want to schedule this worker.
  # user_id: the database id of the slashdeploy User object.
  # github_repo: the repo of the Github Deployment.
  # github_deployment_id: the id of the external Github Deployment.
  def self.schedule(user_id, github_repo, github_deployment_id)
    self.perform_in(DEFAULT_DELAY, user_id, github_repo, github_deployment_id)
  end

  # notify the user if there was an issue otherwise do nothing.
  # user_id: the database id of the slashdeploy User object.
  # github_repo: the repo of the Github Deployment.
  # github_deployment_id: the id of the external Github Deployment.
  def perform(user_id, github_repo, github_deployment_id)
    # get the slashdeploy User object.
    user = User.find(user_id)

    # get the Github Deployment by id.
    github_deployment = SlashDeploy.service.github.get_deployment(user, github_repo, github_deployment_id)

    # get the latest Github Deployment Status.
    deployment_status = SlashDeploy.service.github.last_deployment_status(user, github_deployment.url)

    # if the lastest deployment_status is success exit happily without notifying user.
    return logger.debug "The Github Deployment #{github_deployment.id} has at least one status, nothing to do." if deployment_status

    logger.info "The Github Deployment #{github_deployment.id} of #{github_deployment.repository} @ #{github_deployment.sha} or #{github_deployment.ref} to *#{github_deployment.environment}* did _not_ start. For more details, please read: https://slashdeploy.io/docs#error-1"

    # fetch the user's slack_account related to this deployments Github Org.
    slack_account = user.slack_account_for_github_organization(github_deployment.organization)

    SlashDeploy.service.direct_message(
      slack_account,
      GithubNoDeploymentStatusMessage,
      github_deployment: github_deployment,
      account: slack_account
    )
  end
end
