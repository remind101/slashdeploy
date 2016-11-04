# Handles the status event from github.
class StatusEvent < GitHubEventHandler
  def run
    transaction do
      return unless auto_deployments
      auto_deployments.each do |auto_deployment|
        auto_deployment.context_state event['context'], event['state']
        logger.info "auto_deployment=#{auto_deployment.id} ready=#{auto_deployment.ready?} context=#{event['context']} state=#{event['state']} sha=#{event['sha']}"
        slashdeploy.auto_deploy auto_deployment if auto_deployment.ready?
      end
    end
  end

  private

  def auto_deployments
    @auto_deployments ||= AutoDeployment.lock.active.where(sha: event['sha'])
  end
end
