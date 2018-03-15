# Handles the push event from github.
class PushEvent < GitHubEventHandler
  def run
    return logger.info 'ignoring deleted branch' if deleted?
    return logger.info 'ignoring push from fork' if fork?

    logger.info "ref=#{event['ref']} sha=#{sha} sender=#{event['sender']['login']}"
    transaction do
      if default_branch?
        logger.info "syncing #{SlashDeploy::CONFIG_FILE_NAME}"
        slashdeploy.update_repository_config(repository)
      end
      return logger.info 'not configured for automatic deployments' unless environments
      return logger.info 'skipping continuous delivery because commit message' if skip?
      environments.each do |environment|
        auto_deployment = slashdeploy.create_auto_deployment(environment, sha, deployer)
        logger.info "auto_deployment=#{auto_deployment.id} ready=#{auto_deployment.ready?} deployer=#{auto_deployment.deployer.identifier}"
      end
    end
  end

  private

  def skip?
    SlashDeploy::CD_SKIP.match(event['head_commit']['message'])
  end

  # Returns true if the ref that was pushed to is the default branch for the
  # repository.
  def default_branch?
    event['ref'] == "refs/heads/#{event['repository']['default_branch']}"
  end

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
  # If we don't know who they are, the deployment will be attributed to the
  # SlashDeploy app.
  def deployer
    @account ||= GitHubAccount.find_by(id: event['sender']['id'])
    @account ? @account.user : nil
  end
end
