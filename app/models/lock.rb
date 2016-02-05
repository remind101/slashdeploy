# Lock represents a lock obtained on an environment.
class Lock < ActiveRecord::Base
  belongs_to :environment
  belongs_to :user

  scope :active, -> { where(active: true) }

  def unlock!
    update_attributes(active: false)
  end
end
