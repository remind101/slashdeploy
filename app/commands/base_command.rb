# BaseCommand is a base command for other commands to inherit from. Commands
# should implement the `run` method.
class BaseCommand
  include SlashDeploy::Commands::Rendering

  attr_reader :slashdeploy

  def initialize(slashdeploy)
    @slashdeploy = slashdeploy
  end

  def run(_user, _cmd, _params)
    fail NotImplementedError
  end
end
