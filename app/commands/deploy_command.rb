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
      Slash.say("Created deployment request for #{req}")
    rescue SlashDeploy::RedCommitError => e
      Slash.say <<-EOF
The following commit status checks failed:
#{e.failing_contexts.map { |ctx| "* #{ctx.context}" }.join("\n")}
You can ignore commit status checks by using `#{cmd.request.command} #{cmd.request.text}!`
EOF
    rescue SlashDeploy::EnvironmentLockedError => e
      Slash.say("`#{req.environment}` is locked: #{e.lock.message}")
    end
  end
end
