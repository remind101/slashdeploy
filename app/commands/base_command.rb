# BaseCommand is a base command for other commands to inherit from. Commands
# should implement the `run` method.
class BaseCommand
  include SlashDeploy::Commands::Rendering

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
    logger.with_module(self.class) do
      logger.info('running command')
      run
    end
  end

  def run
    fail NotImplementedError
  end

  def render(template, assigns = {})
    logger.info "template=#{template} rendering"
    super template, assigns.merge(user: user, params: params, request: request)
  end

  private

  def user
    env['user']
  end

  def cmd
    env['cmd']
  end

  def request
    cmd.request
  end

  def params
    env['params']
  end

  def logger
    Rails.logger
  end

  delegate :transaction, to: :'ActiveRecord::Base'
end
