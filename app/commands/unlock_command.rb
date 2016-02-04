# UnlockCommand handles the `/deploy unlock` command.
class UnlockCommand < BaseCommand
  def run(user, _cmd, params)
    req = UnlockRequest.new(
      repository:  params['repository'],
      environment: params['environment']
    )
    slashdeploy.unlock_environment(user, req)
    say :unlocked, req: req
  end
end
