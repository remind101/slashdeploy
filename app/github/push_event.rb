# Handles the push event from github.
class PushEvent < GitHubEventHandler
  def run
    return logger.info 'ignoring deleted branch' if deleted?
    return logger.info 'ignoring push from fork' if fork?

    logger.info "ref=#{event['ref']} sha=#{sha} sender=#{event['sender']['login']}"
    transaction do
      return logger.info 'not configured for automatic deployments' unless environments
      environments.each do |environment|
        auto_deployment = slashdeploy.create_auto_deployment(environment, sha, deployer(environment))
        logger.info "auto_deployment=#{auto_deployment.id} ready=#{auto_deployment.ready?} deployer=#{auto_deployment.user.identifier}"
      end
    end
  end

  private

  # Returns true if this push event was triggered from a fork.
  def fork?
    event['repository']['fork']
  end

  # Returns true if the push event was from a deleted ref.
  def deleted?
    event['deleted']
  end

  # The git commit sha to deploy
  def sha
    event['head_commit']['id']
  end

  # Returns the environment that's configured to auto deploy this git ref.
  def environments
    @environments ||= repository.auto_deploy_environments_for_ref(event['ref'])
  end

  # Returns the user that should be attributed with the deployment. This will
  # be the user that pushed to GitHub if we know who they are in SlashDeploy.
  def deployer(environment)
    account = GitHubAccount.find_by(id: event['sender']['id'])
    account ? account.user : GitHubApp.new(installation)
  end
end
