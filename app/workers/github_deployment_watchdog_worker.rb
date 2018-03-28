class GithubDeploymentWatchdogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deployment_watchdog'

  # default time to wait until our worker wakes up.
  DEFAULT_DELAY = 30.seconds

  # create a class method to hardcode how we want to schedule this worker.
  # user_id: the database id of the slashdeploy User object.
  # github_deployment: an instance of class app/model/deployment::Deployment
  def self.schedule(user_id, github_deployment)
    self.perform_in(DEFAULT_DELAY, user_id, github_deployment.url)
  end

  # notify the user if there was an issue otherwise do nothing.
  # user_id: the database id of the slashdeploy User object.
  # github_deployment: an instance of class app/model/deployment::Deployment
  def perform(user_id, github_deployment)
    # get the slashdeploy User object.
    user = User.find(user_id)

    # get the latest Github Deployment Status.
    deployment_status = SlashDeploy.service.github.last_deployment_status(user, github_deployment.url)

    # if the lastest deployment_status is success exit happily without notifying user.
    return logger.debug "The Github Deployment #{github_deployment.id} has at least one status, nothing to do." if deployment_status

    logger.info "The Github Deployment #{github_deployment.id} of #{github_deployment.repository} @ #{github_deployment.sha} or #{github_deployment.ref} to *#{github_deployment.environment}* did _not_ start. Please review this repo's `.slashdeploy.yml` file and/or have @OpsEng review this repo's Empire Github App Integration Webhooks (for more details, visit: https://remind.quip.com/UbN0AaMDsn8N#dcPACAHqhCJ)"
    SlashDeploy.service.direct_message(
      user.slack_account,
      GithubNoDeploymentStatusMessage,
      github_deployment: github_deployment,
      account: user.slack_account
    )
  end
end
