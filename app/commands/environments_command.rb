# EnvironmentsCommand handles the `/deploy where` subcommand.
class EnvironmentsCommand < BaseCommand
  def run
    transaction do
      repo = Repository.with_name(params['repository'])
      return Slash.reply(ValidationErrorMessage.build(record: repo)) if repo.invalid?

      slashdeploy.authorize! user.user, repo

      Slash.say EnvironmentsMessage.build \
        repository: repo
    end
  end
end
