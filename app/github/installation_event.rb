# Handles the installation event from github.
class InstallationEvent < GitHubEventHandler
  def run
    transaction do
      case action
      when 'created'
        Installation.create!(id: installation_id)
      when 'deleted'
        Installation.destroy(installation_id)
      else
        fail "Unknown action: #{action}"
      end
    end
  end

  def action
    event['action']
  end

  def installation_id
    event['installation']['id']
  end
end
