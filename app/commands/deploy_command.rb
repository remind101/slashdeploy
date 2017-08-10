# DeployCommand handles creating deployments.
class DeployCommand < BaseCommand
  def run
    transaction do
      repo = Repository.with_name(params['repository'])
      return Slash.reply(ValidationErrorMessage.build(record: repo)) if repo.invalid?

      env = repo.environment(params['environment'])
      return Slash.reply(ValidationErrorMessage.build(record: env)) if env.invalid?

      begin
        resp = slashdeploy.create_deployment(
          user,
          env,
          params['ref'],
          force: params['force']
        )

        # If we deployed a ref that's not the environment's default, we'll ask
        # them if they want to lock the environment.
        lock_action = if resp.deployment.ref != env.default_ref && !env.locked_by?(user)
                        slashdeploy.create_message_action(
                          LockAction,
                          repository: repo.to_s,
                          environment: env.to_s
                        )
                      end

        # If the environment is locked by this user, and they're deploying the
        # default ref for the environment, then ask them if they want to unlock
        # it. This hinges on the assumption that you generally lock when you
        # want to test feature branches.
        unlock_action = if resp.deployment.ref == env.default_ref && env.locked_by?(user)
                          slashdeploy.create_message_action(
                            UnlockAction,
                            repository: repo.to_s,
                            environment: env.to_s
                          )
                        end

        m = DeploymentCreatedMessage.build \
          environment: env,
          deployment: resp.deployment,
          last_deployment: resp.last_deployment,
          lock_action: lock_action,
          unlock_action: unlock_action
        respond env.in_channel?, m
      rescue SlashDeploy::EnvironmentAutoDeploys
        message_action = slashdeploy.create_message_action(
          DeployAction,
          params.merge('force' => true)
        )
        Slash.reply AutoDeploymentConfiguredMessage.build \
          environment: env,
          message_action: message_action
      rescue GitHub::RedCommitError => e
        message_action = slashdeploy.create_message_action(
          DeployAction,
          params.merge('force' => true)
        )
        Slash.reply RedCommitMessage.build \
          contexts: e.bad_contexts,
          message_action: message_action
      rescue GitHub::BadRefError => e
        Slash.reply BadRefMessage.build \
          repository: repo,
          ref: e.ref
      rescue SlashDeploy::EnvironmentLockedError => e
        message_action = slashdeploy.create_message_action(
          LockAction,
          force: true,
          repository: params['repository'],
          environment: params['environment'],
          message: params['message']
        )
        Slash.reply EnvironmentLockedMessage.build \
          environment: env,
          lock: e.lock,
          slack_team: account.slack_team,
          message_action: message_action
      end
    end
  end

  def respond(in_channel, message)
    if in_channel
      Slash.say message
    else
      Slash.reply message
    end
  end
end
