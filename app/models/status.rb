# Status represents the red/green state of a git commit per context.
class Status < ActiveRecord::Base
  belongs_to :auto_deployment, foreign_key: :sha, primary_key: :sha

  # Scopes statuses to only those that have succeeded.
  scope :success, -> { where(state: CommitStatusContext::SUCCESS) }

  # Pruneable returns all statuses that aren't part of an active auto deployment.
  scope :pruneable, -> { joins(:auto_deployment).merge(AutoDeployment.inactive) }

  # Tracks the new state of a context on a commit.
  #
  # event - a GitHub `status` event payload.
  #
  # Returns the Status object.
  def self.track(event)
    create! \
      sha: event['sha'],
      context: event['context'],
      state: event['state'],
      description: event['description'],
      target_url: event['target_url']
  end

  # Returns a CommitStatusContext object for this Status.
  def commit_status_context
    CommitStatusContext.new(state: state, context: context)
  end

  delegate :pending?, :success?, :failure?, to: :commit_status_context
end
