class DeploymentWatchdogWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deployment_watchdog'

  # default time to wait until our worker wakes up.
  DEFAULT_DELAY = 1.hour

  # create a class method to hardcode how we want to schedule this worker.
  def self.schedule(auto_deployment_id)
    self.perform_in(DEFAULT_DELAY, auto_deployment_id)
  end

  def perform(auto_deployment_id)
    auto_deployment = AutoDeployment.find(auto_deployment_id)
    # an inactive auto_deployment was either deployed, or superceded
    # by another auto_deployment. Either way we exit without notifying.
    return logger.debug "auto_deployment id #{auto_deployment.id} is inactive which means it was already deployed or superceded." if auto_deployment.inactive?
    if auto_deployment.pending?
      logger.info "There was an issue with auto_deployment id #{auto_deployment.id}. Seems to be hung on #{auto_deployment.pending_statuses}"
      SlashDeploy.service.direct_message(
        auto_deployment.slack_account,
        AutoDeploymentStuckPendingMessage,
        auto_deployment: auto_deployment,
        account: auto_deployment.slack_account
      )
    end
  end
end
