class BoomCommand < BaseCommand
  def run(user, cmd, params)
    fail 'Boom'
  end
end
