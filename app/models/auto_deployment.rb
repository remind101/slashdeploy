# An AutoDeployment manages the lifecycle of an automatic deployment of a git
# sha and ensures that all of the commit statuses are passing.
class AutoDeployment < ActiveRecord::Base
  belongs_to :environment
  belongs_to :user
  has_many :statuses, primary_key: :sha, foreign_key: :sha

  # there may be only one AutoDeployment per environment + sha.
  validates :sha, uniqueness: {
    scope: :environment,
    message: "there may be only one AutoDeployment per environment + sha."
  }

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
    return STATE_INACTIVE if inactive?

    statuses = required_statuses

    # If any statuses are in a "pending" state, then the auto deployment is
    # also pending.
    return STATE_PENDING if statuses.any?(&:pending?)

    # For an AutoDeployment to be considered "ready" to be deployed, all of the
    # required commit status contexts need to be in a `success` state.
    return STATE_READY if statuses.all?(&:success?)

    # If we've reached here, then some of the required commit status contexts
    # are not in a `success` state (could be `pending`, `error` or `failure`).
    # If all of the required commit statuses are NOT in a pending state (e.g
    # some are `failure` and some are `success`), we'll considered this auto
    # deployment to be in a `failed` state.
    #
    # It's entirely possible for an auto deployment to transition from `failed`
    # to `pending` or `ready` if the user fixes the commit status that is
    # failing.
    return STATE_FAILED if statuses.any?(&:failure?)

    fail 'Unreachable'
  end

  def inactive?
    !active
  end

  def ready?
    state == STATE_READY
  end

  def pending?
    state == STATE_PENDING
  end

  def failed?
    state == STATE_FAILED
  end

  # Returns the required commit status contexts that are currently in a pending state.
  def pending_statuses
    required_statuses.select(&:pending?)
  end

  # Returns the required commit status contexts that are currently in a success state.
  def success_statuses
    required_statuses.select(&:success?)
  end

  # Returns the required commit status contexts that are currently in a failing state.
  def failing_statuses
    required_statuses.select(&:failure?)
  end

  # Returns the entity we should attribute the deployment to.
  #
  # It's possible that SlashDeploy doesn't know the GitHub user that created
  # the GitHub Deployment, if they've never logged into SlashDeploy. In that
  # case, we attribute the deployment to the GitHub app itself. From a security
  # perspective, this is safe because we've already verified that the webhook
  # we received was from GitHub, and we trust GitHub.
  def deployer
    user || environment.installation
  end

  # Returns the slack account that should be used when DM'ing the user about
  # this auto deployment.
  def slack_account
    environment.slack_account_for(deployer)
  end

  # Returns a Status object for the current state of all required commit status
  # contexts. If the state field is nil, it means we haven't record a Status
  # object for it yet.
  def required_statuses
    # TODO(ejholmes): Optimize this query.
    required_contexts.map do |context|
      statuses.latest(context)
    end
  end

  private

  def required_contexts
    environment.required_contexts || []
  end
end
