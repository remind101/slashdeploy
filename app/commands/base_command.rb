# BaseCommand is a base command for other commands to inherit from. Commands
# should implement the `run` method.
class BaseCommand
  attr_reader :env
  attr_reader :slashdeploy

  def self.call(env)
    new(env, ::SlashDeploy.service).call
  end

  def initialize(env, slashdeploy)
    @env = env
    @slashdeploy = slashdeploy
  end

  def call
    $tracer.trace('slack.command') do |span|
      span.resource = self.class.name

      logger.with_module(self.class) do
        logger.info('running command')
        run
      end
    end
  end

  def run
    fail NotImplementedError
  end

  private

  def user
    env['user']
  end

  def cmd
    env['cmd']
  end

  def params
    env['params']
  end

  def logger
    Rails.logger
  end

  delegate :transaction, to: :'ActiveRecord::Base'
end
