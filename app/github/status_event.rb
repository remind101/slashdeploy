# Handles the status event from github.
class StatusEvent < GitHubEventHandler
  def run
    transaction do
      return unless auto_deployment
      auto_deployment.context_state event['context'], event['state']
      logger.info "auto_deployment=#{auto_deployment.id} ready=#{auto_deployment.ready?} context=#{event['context']} state=#{event['state']} sha=#{event['sha']}"
      slashdeploy.auto_deploy auto_deployment
    end
  end

  private

  def auto_deployment
    @auto_deployment ||= AutoDeployment.lock.active.find_by(sha: event['sha'])
  end
end
