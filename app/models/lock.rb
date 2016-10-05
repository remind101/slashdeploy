# Lock represents a lock obtained on an environment.
class Lock < ActiveRecord::Base
  belongs_to :environment
  belongs_to :user

  scope :active, -> { where(active: true) }
  scope :waiting, -> { where(waiting: true) }
  scope :for_user, -> (user) { where(user_id: user.id) }

  def lock!
    update_attributes!(active: true)
  end

  def unlock!
    update_attributes!(active: false)
  end

  def dequeue!
    update_attributes!(waiting: false)
  end

  def repository
    environment.repository
  end
end
