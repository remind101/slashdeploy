# Handles the push event from github.
class PushEvent < GithubEventHandler
  def run
    transaction do
      return unless environment
      slashdeploy.create_deployment deployer, environment, event['head']
    end
  end

  private

  def branch
    # TODO: tags? forks?
    @branch ||= event['ref'].gsub('refs/heads/', '')
  end

  def environment
    @environment = repository.auto_deploy_environment_for_branch(branch)
  end

  def deployer
    @deployer ||= begin
                    account = GithubAccount.find_by(id: event['sender']['id'])
                    return environment.auto_deploy_user unless account
                    account.user
                  end
  end
end
