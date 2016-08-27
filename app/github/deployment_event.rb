# Handles the deployment_status event from github.
class DeploymentEvent < GitHubEventHandler
  DEPLOY_TARGETS = %i(circleci)

  def run
    return logger.info('no matching github repo') unless repository
    DEPLOY_TARGETS.each do |target|
      slashdeploy.deploy(target, repository, event) if repository.deploy_to?(target)
    end
  end

  private

  def repository
    @repository ||= Repository.find_by(name: event['repository']['full_name'])
  end
end
