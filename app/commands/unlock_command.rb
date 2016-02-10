# UnlockCommand handles the `/deploy unlock` command.
class UnlockCommand < BaseCommand
  def run(slack_user, _cmd, params)
    transaction do
      repo = Repository.with_name(params['repository'])
      env  = repo.environment(params['environment'])

      slashdeploy.unlock_environment(slack_user.user, env)
      say :unlocked, repository: repo, environment: env
    end
  end
end
