# UnlockAllCommand handles the `/deploy unlock all` command.
class UnlockAllCommand < BaseCommand
  def run
    transaction do
      active_locks = user.locks.active
      slashdeploy.unlock_all(user)
      Slash.say UnlockedAllMessage.build active_locks
    end
  end
end
