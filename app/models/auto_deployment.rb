# An AutoDeployment manages the lifecycle of an automatic deployment of a git
# sha and ensures that all of the commit statuses are passing.
class AutoDeployment < ActiveRecord::Base
  belongs_to :environment
  belongs_to :user
  has_many :statuses, primary_key: :sha, foreign_key: :sha

  # Deployment is waiting on required commit statuses to pass.
  STATE_PENDING = :pending
  # All required commit statuses are passing, and the deployment is ready to be deployed.
  STATE_READY = :ready
  # All required commit statuses have a non-pending status, but some are
  # failing or errored. It's possible for an AutoDeployment to transition from
  # FAILED to READY if the user fixes the commit status.
  STATE_FAILED = :failed
  # Deployment has either been deployed, or superceded by another auto deployment.
  STATE_INACTIVE = :inactive

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

  # Returns the current state of this AutoDeployment.
  def state
    return STATE_INACTIVE unless active?
    return STATE_READY if environment.required_contexts.blank?
    return STATE_READY if required_statuses.all?(&:success?)
    return STATE_FAILED if required_statuses.all? { |context| !context.pending? }
    STATE_PENDING
  end

  def ready?
    state == STATE_READY
  end

  # Returns a Status object for the current state of all required commit status
  # contexts. If the state field is nil, it means we haven't record a Status
  # object for it yet.
  def required_statuses
    # TODO(ejholmes): Optimize this query.
    environment.required_contexts.map do |context|
      status = statuses.order('id desc').find_by(context: context)
      status || Status.new(context: context, state: nil)
    end.compact
  end

  # Returns the required commit status contexts that are currently in a failing state.
  def failing_statuses
    required_statuses.select(&:failure?)
  end

  # Returns the slack account that should be used when DM'ing the user about this auto deployment.
  def slack_account
    user.slack_account_for_github_organization(environment.repository.organization)
  end
end
