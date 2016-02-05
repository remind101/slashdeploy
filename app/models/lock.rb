# Lock represents a lock obtained on an environment.
class Lock < ActiveRecord::Base
  belongs_to :environment

  scope :active, -> { where(active: true) }
end
