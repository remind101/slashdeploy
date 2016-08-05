# Add desc
class ActionCommand
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
    callback_id = action_payload.request.callback_id
    message_action = MessageAction.find_by_callback_id(callback_id)
    Object.const_get(message_action.command).call(env.merge('params' => message_action.command_params.to_h))
  end

  def user
    env['user']
  end

  def action_payload
    env['action']
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
