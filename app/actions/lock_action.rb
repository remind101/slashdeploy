
class LockAction < BaseAction
  def run
    transaction do
      env.merge!('params' => message_action.action_params.to_h)
      LockCommand.call(env)
    end
  end
end
