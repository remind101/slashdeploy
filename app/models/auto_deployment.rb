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
  scope :inactive, -> { where(active: false) }

  # Returns auto deployments that are older than the given auto deployment.
  scope :older_than, -> (auto_deployment) { where(arel_table[:id].lt(auto_deployment.id)) }

  # Marks this auto deployment as done and deactivates it, as well as any auto
  # deployments to the environment that are older than this (which should be
  # considered obsolete).
  def done!
    transaction do
      update_attributes!(active: false)
      obsolete_auto_deployments = environment.auto_deployments.older_than(self).active
      obsolete_auto_deployments.update_all(active: false)
    end
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

    true
  end
end
