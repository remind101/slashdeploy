# Handles the status event from github.
class StatusEvent < GitHubEventHandler
  def run
    transaction do
      logger.info "context=#{context.context} state=#{context.state} sha=#{event['sha']}"
      slashdeploy.track_context_state_change event['sha'], context
    end
  end

  private

  def context
    CommitStatusContext.new context: event['context'], state: event['state']
  end

  def auto_deployments
    @auto_deployments ||= AutoDeployment.lock.active.where(sha: event['sha'])
  end
end
