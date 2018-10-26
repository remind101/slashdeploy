# LatestCommand handles the `/deploy latest` subcommand.
class LatestCommand < BaseCommand
  def run
    transaction do
      repo = Repository.with_name(params['repository'])
      return Slash.reply(ValidationErrorMessage.build(record: repo)) if repo.invalid?
      
      env = repo.environment(params['environment'])
      last_deployment = slashdeploy.last_deployment(user, repo, env)

      Slash.say LatestMessage.build \
        last_deployment: last_deployment
    end
  end
end
