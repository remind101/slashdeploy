# DeployCommand handles creating deployments.
class DeployCommand < BaseCommand
  def run(user, cmd, params)
    req = DeploymentRequest.new(
      repository:  params['repository'],
      ref:         params['ref'],
      environment: params['environment'],
      force:       params['force']
    )
    begin
      req = slashdeploy.create_deployment(user, req)
      reply :created, req: req
    rescue SlashDeploy::RedCommitError => e
      reply :red_commit, req: cmd.request, failing_contexts: e.failing_contexts
    rescue SlashDeploy::EnvironmentLockedError => e
      locker = e.lock.user.slack_username(cmd.request.team_id)
      reply :locked, req: req, lock: e.lock, locker: locker
    end
  end
end
