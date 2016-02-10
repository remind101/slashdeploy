# EnvironmentsCommand handles the `/deploy where` subcommand.
class EnvironmentsCommand < BaseCommand
  def run(slack_user, _cmd, params)
    transaction do
      repo = Repository.with_name(params['repository'])
      environments = slashdeploy.environments(slack_user.user, repo)
      say :list, repository: repo, environments: environments
    end
  end
end
