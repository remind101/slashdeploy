# CommitStatusContext represents the red/green state of a git commit per context.
class CommitStatusContext
  include Virtus.value_object

  values do
    attribute :context, String
    attribute :state, String
  end

  def ok?
    state == 'success'
  end

  def bad?
    !ok?
  end
end
