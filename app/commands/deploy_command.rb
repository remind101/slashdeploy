# DeployCommand handles creating deployments.
class DeployCommand < BaseCommand
  def run(user, _cmd, params)
    req = DeploymentRequest.new params
    req = slashdeploy.create_deployment(user, req)
    Slash.say("Created deployment request for #{req}")
  end
end
