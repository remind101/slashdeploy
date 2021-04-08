# LockCommand handles the `/deploy lock` command.
class LockCommand < BaseCommand
  def run
    transaction do
      repo_name = params['repository']
      env_name = params['environment']

      repo = Repository.with_name(repo_name)
      
      if repo.invalid?
        env_name, repo_name = repo_name, env_name
        repo = Repository.with_name(repo_name)
      end

      return Slash.reply(ValidationErrorMessage.build(record: repo)) if repo.invalid?

      env = repo.environment(env_name)

      return Slash.reply(EnvironmentsMessage.build(repository: repo)) unless env
      return Slash.reply(ValidationErrorMessage.build(record: env)) if env.invalid?

      begin
        resp = slashdeploy.lock_environment(user, env, message: params['message'].try(:strip), force: params['force'])
        if resp
          Slash.say LockedMessage.build \
            environment: env,
            stolen_lock: resp.stolen,
            slack_team: account.slack_team
        else
          Slash.say AlreadyLockedMessage.build \
            environment: env
        end
      rescue SlashDeploy::EnvironmentLockedError => e
        message_action = slashdeploy.create_message_action(
          LockAction,
          force: true,
          repository: repo_name,
          environment: env_name,
          message: params['message']
        )

        Slash.reply EnvironmentLockedMessage.build \
          environment:     env,
          lock:            e.lock,
          slack_team:      account.slack_team,
          message_action:  message_action
      end
    end
  end
end
