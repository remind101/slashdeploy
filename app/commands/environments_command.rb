# EnvironmentsCommand handles the `/deploy where` subcommand.
class EnvironmentsCommand < BaseCommand
  def run(user, _cmd, params)
    repo = params['repository']
    environments = slashdeploy.environments(user, repo)
    if environments.empty?
      Slash.say "I don't know about any environments for #{repo}"
    else
      Slash.say "I know about these environments for #{repo}:\n#{environments.map { |e| "* #{e.name}" }.join("\n")}"
    end
  end
end
