# An UnlockRequest provides options for unlocking an environment on a repository.
class UnlockRequest
  include Virtus.value_object

  values do
    # The repository to lock.
    attribute :repository, String
    # The environment to lock.
    attribute :environment, String
  end
end
