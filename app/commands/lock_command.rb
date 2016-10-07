# LockCommand handles the `/deploy lock` command.
class LockCommand < BaseCommand
  def run
    transaction do
      repo = Repository.with_name(params['repository'])
      return Slash.reply(ValidationErrorMessage.build(record: repo)) if repo.invalid?

      env = repo.environment(params['environment'])
      return Slash.reply(ValidationErrorMessage.build(record: env)) if env.invalid?

      begin
        resp = slashdeploy.lock_environment(user.user, env, message: params['message'].try(:strip), force: params['force'])
        if resp
          Slash.say LockedMessage.build \
            environment: env,
            stolen_lock: resp.stolen,
            slack_team: user.slack_team
        else
          # user already owns the active lock
          Slash.say AlreadyLockedMessage.build \
            environment: env
        end
      rescue SlashDeploy::EnvironmentLockedError => e
        message_action = slashdeploy.create_message_action(
          LockAction,
          force: true,
          repository: params['repository'],
          environment: params['environment'],
          message: params['message']
        )

        Slash.reply EnvironmentLockedMessage.build \
          environment:     env,
          lock:            e.lock,
          slack_team:      user.slack_team,
          message_action:  message_action
      end
    end
  end
end
