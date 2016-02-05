# LockCommand handles the `/deploy lock` command.
class LockCommand < BaseCommand
  def run(user, cmd, params)
    req = LockRequest.new(
      repository:  params['repository'],
      environment: params['environment'],
      message:     params['message'].try(:strip)
    )
    resp = slashdeploy.lock_environment(user, req)
    if resp
      stolen = resp.stolen ? resp.stolen.user.slack_username(cmd.request.team_id) : nil
      say :locked, req: req, stolen: stolen
    else
      say :already_locked, req: req
    end
  end
end
