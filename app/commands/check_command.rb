# CheckCommand handles the `/deploy check` command.
class CheckCommand < BaseCommand
  def run
    transaction do
      repo = Repository.with_name(params['repository'])
      return Slash.reply(ValidationErrorMessage.build(record: repo)) if repo.invalid?

      env = repo.environment(params['environment'])
      return Slash.reply(ValidationErrorMessage.build(record: env)) if env.invalid?

      Slash.say CheckMessage.build \
        environment: env,
        lock: env.active_lock,
        slack_team: user.slack_team
    end
  end
end
