# Handles the status event from github.
class StatusEvent < GitHubEventHandler
  def run
    transaction do
      status = Status.track(event)
      slashdeploy.track_context_state_change status
    end
  end
end
