# QueueCommand handles the `/deploy queue` command.
class QueueCommand < BaseCommand
  def run
    transaction do
      repo = Repository.with_name(params['repository'])
      return Slash.reply(ValidationErrorMessage.build(record: repo)) if repo.invalid?

      env = repo.environment(params['environment'])
      return Slash.reply(ValidationErrorMessage.build(record: env)) if env.invalid?

      begin
        position = slashdeploy.queue_user_for_environment(user.user, env, message: params['message'].try(:strip))
        if position
          Slash.say QueuedMessage.build environment: env, position: position
        else
          Slash.say AlreadyQueuedMessage.build environment: env
        end
      rescue SlashDeploy::EnvironmentUnlockedError
        Slash.say AlreadyUnlockedMessage.build environment: env
      end
    end
  end
end
