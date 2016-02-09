# LockCommand handles the `/deploy lock` command.
class LockCommand < BaseCommand
  def run(user, cmd, params)
    transaction do
      repo = Repository.with_name(params['repository'])
      env  = repo.environment(params['environment'])
      resp = slashdeploy.lock_environment(user, env, params['message'].try(:strip))
      if resp
        stolen = resp.stolen ? resp.stolen.user.slack_username(cmd.request.team_id) : nil
        say :locked, environment: env, repository: repo, stolen: stolen
      else
        say :already_locked, environment: env, repository: repo
      end
    end
  end
end
