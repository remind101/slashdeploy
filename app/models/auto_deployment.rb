# An AutoDeployment manages the lifecycle of an automatic deployment of a git
# sha and ensures that all of the commit statuses are passing.
class AutoDeployment < ActiveRecord::Base
  belongs_to :environment
  belongs_to :user
  has_many :statuses, primary_key: :sha, foreign_key: :sha

  # Scopes auto deployments to only return those that are currently active.
  # Active means that a commit was pushed to the repository but not all commit
  # statuses have entered into a failed or success state.
  scope :active, -> { where(active: true) }

  # Marks this auto deployment as cancelled and deactivates it.
  def cancel!
    update_attributes!(active: false)
  end

  # Marks this auto deployment as done and deactivates it.
  def done!
    update_attributes!(active: false)
  end

  # Records the contexts new state.
  def context_state(context, state)
    statuses.create! state: state, context: context
  end

  # Returns true if all of the required contexts for the environment have passed.
  def ready?
    # If the environment doesn't have any required_contexts configured, just
    # return true.
    return true if environment.required_contexts.blank?

    # Only look at commit status contexts that are passing.
    contexts = statuses.success

    environment.required_contexts.each do |name|
      status = contexts.find { |c| c.context == name }
      return false unless status
      return false unless status.success?
    end
  end
end
