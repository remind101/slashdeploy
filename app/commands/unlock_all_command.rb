# UnlockAllCommand handles the `/deploy unlock all` command.
class UnlockAllCommand < BaseCommand
  def run
    transaction do
      locks = slashdeploy.unlock_all(user)
      Slash.say UnlockedAllMessage.build \
        locks: locks
    end
  end
end
