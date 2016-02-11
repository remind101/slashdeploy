class BoomCommand < BaseCommand
  def run(_user, _cmd, _params)
    fail 'Boom'
  end
end
