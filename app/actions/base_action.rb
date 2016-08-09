# BaseAction is a base action for other actions to inherit from. Actions
# should implement the `run` method.
class BaseAction
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
      logger.info('running action')
      run
    end
  end

  def run
    fail NotImplementedError
  end

  private

  # The User object
  def user
    env['user']
  end

  # The Slash::Action object
  def action
    env['action']
  end

  # The MessageAction object
  def message_action
    env['message_action']
  end

  def params
    env['params']
  end

  def logger
    Rails.logger
  end

  delegate :transaction, to: :'ActiveRecord::Base'
end
