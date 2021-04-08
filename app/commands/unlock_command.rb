# UnlockCommand handles the `/deploy unlock` command.
class UnlockCommand < BaseCommand
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

      slashdeploy.unlock_environment(user, env)
      Slash.say UnlockedMessage.build \
        environment: env
    end
  end
end
