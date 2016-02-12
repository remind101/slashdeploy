# Status represents the red/green state of a git commit per context.
class Status < ActiveRecord::Base
  belongs_to :auto_deployment, foreign_key: :sha, primary_key: :sha

  # Scopes statuses to only those that have succeeded.
  scope :success, -> { where(state: CommitStatusContext::SUCCESS) }

  # Returns a CommitStatusContext object for this Status.
  def commit_status_context
    CommitStatusContext.new(state: state, context: context)
  end

  delegate :success?, :failure?, to: :commit_status_context
end
