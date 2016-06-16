# Handles the status event from github.
class StatusEvent < GitHubEventHandler
  def run
    transaction do
      slashdeploy.track_commit_status_context_change event['sha'], commit_status_context
    end
  end

  private

  def commit_status_context
    @commit_status_context ||= CommitStatusContext.new(
      context: event['context'],
      state: event['state']
    )
  end

  def auto_deployment
    @auto_deployment ||= AutoDeployment.active.find_by(sha: event['sha'])
  end
end
