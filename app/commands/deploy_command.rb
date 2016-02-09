# DeployCommand handles creating deployments.
class DeployCommand < BaseCommand
  def run(user, cmd, params)
    transaction do
      repo = Repository.with_name(params['repository'])
      env  = repo.environment(params['environment'])

      begin
        resp = slashdeploy.create_deployment(
          user,
          env,
          params['ref'],
          force: params['force']
        )
        respond env.in_channel?, :created, resp: resp
      rescue SlashDeploy::RedCommitError => e
        reply :red_commit, req: cmd.request, failing_contexts: e.failing_contexts
      rescue SlashDeploy::EnvironmentLockedError => e
        locker = e.lock.user.slack_username(cmd.request.team_id)
        reply :locked, environment: env, lock: e.lock, locker: locker
      end
    end
  end

  def respond(in_channel, text, assigns = {})
    if in_channel
      say text, assigns
    else
      reply text, assigns
    end
  end
end
