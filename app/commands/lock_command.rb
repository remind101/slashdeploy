# LockCommand handles the `/deploy lock` command.
class LockCommand < BaseCommand
  def run(user, _cmd, params)
    req = LockRequest.new(
      repository:  params['repository'],
      environment: params['environment'],
      message:     params['message'].try(:strip)
    )
    slashdeploy.lock_environment(user, req)
    Slash.say "Locked `#{req.environment}` on #{req.repository}"
  end
end
