# UnlockAllCommand handles the `/deploy unlock all` command.
class UnlockAllCommand < BaseCommand
  def run
    transaction do
      # Gather an Array of Environment objects from each of the user's active locks.
      environments = []
      user.locks.active.each do |lock|
        environments.push(lock.environment)
      end
      slashdeploy.unlock_all(user)
      Slash.say UnlockedAllMessage.build \
        environments: environments
    end
  end
end
