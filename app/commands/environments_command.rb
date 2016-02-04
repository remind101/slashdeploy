# EnvironmentsCommand handles the `/deploy where` subcommand.
class EnvironmentsCommand < BaseCommand
  def run(user, _cmd, params)
    repo = params['repository']
    environments = slashdeploy.environments(user, repo)
    if environments.empty?
      say :none, repo: repo
    else
      say :list, repo: repo, environments: environments
    end
  end
end
