# LockCommand handles the `/deploy lock` command.
class LockCommand < BaseCommand
  def run(user, _cmd, params)
    req = LockRequest.new(
      repository:  params['repository'],
      environment: params['environment'],
      message:     params['message'].try(:strip)
    )
    slashdeploy.lock_environment(user, req)
    say :locked, req: req
  end
end
