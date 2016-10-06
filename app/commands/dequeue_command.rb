# DequeueCommand handles the `/deploy dequeue` command.
class DequeueCommand < BaseCommand
  def run
    transaction do
      repo = Repository.with_name(params['repository'])
      return Slash.reply(ValidationErrorMessage.build(record: repo)) if repo.invalid?

      env = repo.environment(params['environment'])
      return Slash.reply(ValidationErrorMessage.build(record: env)) if env.invalid?

      begin
        removed = slashdeploy.dequeue_user_for_environment(user.user, env)
        if removed
          Slash.say DequeuedMessage.build environment: env
        else
          Slash.say NotInQueueMessage.build environment: env
        end
      rescue SlashDeploy::EnvironmentUnlockedError => e
        Slash.say AlreadyUnlockedMessage.build environment: env
      end
    end
  end
end
