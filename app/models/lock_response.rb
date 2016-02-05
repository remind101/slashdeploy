# LockResponse is returned from a request to lock an environment.
class LockResponse
  include Virtus.value_object

  values do
    # The new lock
    attribute :lock, Lock

    # The previous lock, or nil if there was none.
    attribute :stolen, Lock
  end

  def stolen?
    previous_lock.present?
  end
end
