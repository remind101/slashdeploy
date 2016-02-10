class BoomCommand < BaseCommand
  def run(_slack_user, _cmd, _params)
    fail 'Boom'
  end
end
