# Handles the status event from github.
class StatusEvent < GithubEventHandler
  def run
    transaction do
      return unless auto_deployment
      auto_deployment.context_state event['context'], event['state']
      slashdeploy.auto_deploy auto_deployment
    end
  end

  private

  def auto_deployment
    @auto_deployment ||= AutoDeployment.active.find_by(sha: event['sha'])
  end
end
