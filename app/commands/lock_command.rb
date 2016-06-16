# LockCommand handles the `/deploy lock` command.
class LockCommand < BaseCommand
  def run
    transaction do
      repo = Repository.with_name(params['repository'])
      env  = repo.environment(params['environment'])
      begin
        resp = slashdeploy.lock_environment(user.user, env, message: params['message'].try(:strip), force: params['force'])
        if resp
          Slash.say LockedMessage.build \
            environment: env,
            stolen_lock: resp.stolen,
            slack_team: user.slack_team
        else
          Slash.say AlreadyLockedMessage.build \
            environment: env
        end
      rescue SlashDeploy::EnvironmentLockedError => e
        Slash.reply EnvironmentLockedMessage.build \
          environment: env,
          lock: e.lock,
          slack_team: user.slack_team,
          request: request
      end
    end
  end
end
