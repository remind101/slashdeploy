# EnvironmentsCommand handles the `/deploy where` subcommand.
class EnvironmentsCommand < BaseCommand
  def run
    transaction do
      repo = Repository.with_name(params['repository'])
      slashdeploy.authorize! user.user, repo
      Slash.say EnvironmentsMessage.build \
        repository: repo
    end
  end
end
