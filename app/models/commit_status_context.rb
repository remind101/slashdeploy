# CommitStatusContext represents the red/green state of a git commit per context.
# The github "status" API allows third party systems like CircleCI and Conveyor to
# emit status payloads to Github to be centrally managed.
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
    state == SUCCESS
  end

  def failure?
    state == FAILURE || state == ERROR
  end

  def pending?
    state == PENDING
  end

  def to_s
    "#{context} (#{state})"
  end
end
