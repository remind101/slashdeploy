# Handles the push event from github.
class PushEvent < GithubEventHandler
  def run(repository, event)
    branch = event['ref'].gsub('refs/heads/', '')

    transaction do
      environment = repository.auto_deploy_environment_for_branch(branch)
      return unless environment
      user = deployer(event['sender']['id'], environment.auto_deploy_user)
      slashdeploy.create_deployment user, environment, event['head']
    end
  end

  private

  def deployer(sender_id, fallback)
    account = GithubAccount.find_by(id: sender_id)
    return fallback unless account
    account.user
  end
end
