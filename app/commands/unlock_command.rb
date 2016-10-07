# UnlockCommand handles the `/deploy unlock` command.
class UnlockCommand < BaseCommand
  def run
    transaction do
      repo = Repository.with_name(params['repository'])
      return Slash.reply(ValidationErrorMessage.build(record: repo)) if repo.invalid?

      env = repo.environment(params['environment'])
      return Slash.reply(ValidationErrorMessage.build(record: env)) if env.invalid?

      slashdeploy.unlock_environment(user.user, env)
      new_active_lock = slashdeploy.give_lock_to_next_user(env)

      if new_active_lock
        Thread.new do
          slashdeploy.direct_message \
            new_active_lock.user.slack_account_for_github_organization(repo.organization),
            LockedMessage,
            environment: env,
            stolen_lock: false,
            slack_team: user.slack_team
        end

        Slash.say PassedLockMessage.build \
          environment: env,
          new_active_lock: new_active_lock,
          slack_team: user.slack_team
      else
        Slash.say UnlockedMessage.build \
          environment: env
      end
    end
  end
end
