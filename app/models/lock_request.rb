# A LockRequest provides options for locking an environment on a repository.
class LockRequest
  include Virtus.value_object

  values do
    # The repository to lock.
    attribute :repository, String
    # The environment to lock.
    attribute :environment, String
    # A message to indicate why it's locked.
    attribute :message, String
  end
end
