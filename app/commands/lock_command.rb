# LockCommand handles the `/deploy lock` command.
class LockCommand < BaseCommand
  def run
    transaction do
      repo = Repository.with_name(params['repository'])
      return Slash.reply(ValidationErrorMessage.build(record: repo)) if repo.invalid?

      env = repo.environment(params['environment'])
      return Slash.reply(ValidationErrorMessage.build(record: env)) if env.invalid?

      begin
        previous_owner = locker(env)
        resp = slashdeploy.lock_environment(user, env, message: params['message'].try(:strip), force: params['force'])
        if resp
          if previous_owner
            slashdeploy.direct_message \
              previous_owner.slack_account_for_github_organization(account.github_organization),
              LockStolenMessage,
              environment: env,
              thief: user,
              slack_team: account.slack_team
          end
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
          repository: params['repository'],
          environment: params['environment'],
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

  private

  def locker(env)
    lock(env).try(:user)
  end

  def lock(env)
    env.active_lock
  end
end
