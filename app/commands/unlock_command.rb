# UnlockCommand handles the `/deploy unlock` command.
class UnlockCommand < BaseCommand
  def run
    transaction do
      repo = Repository.with_name(params['repository'])
      return Slash.reply(ValidationErrorMessage.build(record: repo)) if repo.invalid?

      env = repo.environment(params['environment'])
      return Slash.reply(EnvironmentsMessage.build(repository: repo)) unless env
      return Slash.reply(ValidationErrorMessage.build(record: env)) if env.invalid?

      slashdeploy.unlock_environment(user, env)
      Slash.say UnlockedMessage.build \
        environment: env
    end
  end
end
