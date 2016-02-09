# Handles the push event from github.
class PushEvent < GithubEventHandler
  def run(repository, event)
    branch = event['ref'].gsub('refs/heads/', '')

    transaction do
      environment = repository.auto_deploy_environment_for_branch(branch)
      return unless environment
      slashdeploy.create_deployment environment.auto_deploy_user, environment, event['head']
    end
  end
end
