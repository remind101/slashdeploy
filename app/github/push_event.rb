# Handles the push event from github.
class PushEvent < GithubEventHandler
  def run
    transaction do
      return unless environment
      slashdeploy.create_deployment deployer, environment, event['head']
    end
  end

  private

  def environment
    @environment = repository.auto_deploy_environment_for_ref(event['ref'])
  end

  def deployer
    @deployer ||= begin
                    account = GithubAccount.find_by(id: event['sender']['id'])
                    return environment.auto_deploy_user unless account
                    account.user
                  end
  end
end
