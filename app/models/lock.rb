# Lock represents a lock obtained on an environment.
class Lock < ActiveRecord::Base
  belongs_to :environment
  belongs_to :user

  scope :active, -> { where(active: true) }

  def inactive?
    !active
  end

  def unlock!
    update_attributes!(active: false)
  end

  def repository
    environment.repository
  end

  def slack_account
    environment.slack_account_for(user)
  end
end
