# DeployCommand handles creating deployments.
class DeployCommand < BaseCommand
  def run(user, _cmd, params)
    req = DeploymentRequest.new(
      repository:  params['repository'],
      ref:         params['ref'],
      environment: params['environment'],
      force:       params['force']
    )
    begin
      req = slashdeploy.create_deployment(user, req)
      Slash.say("Created deployment request for #{req}")
    rescue SlashDeploy::EnvironmentLockedError => e
      Slash.say("`#{req.environment}` is locked: #{e.lock.message}")
    end
  end
end
