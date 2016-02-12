# CommitStatusContext represents the red/green state of a git commit per context.
class CommitStatusContext
  include Virtus.value_object

  # https://developer.github.com/v3/repos/statuses/#create-a-status
  SUCCESS = 'success'.freeze
  FAILURE = 'failure'.freeze
  PENDING = 'pending'.freeze
  ERROR   = 'error'.freeze

  values do
    attribute :context, String
    attribute :state, String
  end

  def success?
    state == 'success'
  end

  def failure?
    !success?
  end
end
