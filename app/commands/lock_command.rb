# LockCommand handles the `/deploy lock` command.
class LockCommand < BaseCommand
  def run
    transaction do
      repo = Repository.with_name(params['repository'])
      env  = repo.environment(params['environment'])
      begin
        resp = slashdeploy.lock_environment(user.user, env, message: params['message'].try(:strip), force: params['force'])
        if resp
          stealer = resp.stolen ? SlackUser.new(resp.stolen.user, user.slack_team) : nil
          say :locked, environment: env, repository: repo, stealer: stealer
        else
          say :already_locked, environment: env, repository: repo
        end
      rescue SlashDeploy::EnvironmentLockedError => e
        say :lock, environment: env, repository: repo, lock: e.lock, locker: SlackUser.new(e.lock.user, user.slack_team)
      end
    end
  end
end
