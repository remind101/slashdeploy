class LockNagWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'lock_nag'

  # default time to wait until our worker wakes up.
  DEFAULT_DELAY = 3.hours

  # create a class method to hardcode how we want to schedule this worker.
  def self.schedule(lock_id)
    self.perform_in(DEFAULT_DELAY, lock_id)
  end

  def perform(lock_id)
    lock = Lock.find(lock_id)

    # an inactive lock does not need to be processed.
    return logger.debug "lock id (#{lock.id}) is already inactive, skipping." if lock.inactive?

    logger.info "Nagging user about lock id (#{lock.id}) and rescheduling another lock nag for the future."

    # reschedule another nag.
    self.class.schedule(lock.id)

    # create a message_action to let the user click a button to unlock
    # the environment from the nag message itself.
    message_action = SlashDeploy.service.create_message_action(
      UnlockAction,
      repository: lock.repository.name,
      environment: lock.environment.name,
    )

    # send the user a nagging direct message with a button for redemption.
    SlashDeploy.service.direct_message(
      lock.slack_account,
      LockNagMessage,
      lock: lock,
      account: lock.slack_account,
      message_action:  message_action,
    )
  end
end
