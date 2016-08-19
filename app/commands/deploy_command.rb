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
          user.user,
          env,
          params['ref'],
          force: params['force']
        )
        m = DeploymentCreatedMessage.build \
          deployment: resp.deployment,
          last_deployment: resp.last_deployment
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
          failing_contexts: e.failing_contexts,
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
          slack_team: user.slack_team,
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
