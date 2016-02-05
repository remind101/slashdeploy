# LockCommand handles the `/deploy lock` command.
class LockCommand < BaseCommand
  def run(user, _cmd, params)
    req = LockRequest.new(
      repository:  params['repository'],
      environment: params['environment'],
      message:     params['message'].try(:strip)
    )
    resp = slashdeploy.lock_environment(user, req)
    if resp
      say :locked, req: req, stolen: resp.stolen
    else
      say :already_locked, req: req
    end
  end
end
