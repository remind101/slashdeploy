# LockResponse is returned from a request to lock an environment.
class LockResponse
  include Virtus.value_object

  values do
    attribute :lock, Lock
    attribute :stolen, Boolean
  end
end
