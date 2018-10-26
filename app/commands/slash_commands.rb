# SlashCommands is a slash handler that provides the SlashDeploy slack slash
# commands. This class is simply a demuxer that routes requests to the appropriate
# sub command.
class SlashCommands
  REPO = /(?<repository>\S+?)/
  ENV  = /(?<environment>\S+?)/
  REF  = /(?<ref>\S+?)/

  attr_reader :router

  # order matters, uses first match priority.
  def self.route
    router = Slash::Router.new
    router.match match_regexp(/^help$/), HelpCommand
    router.match match_regexp(/^where #{REPO}$/), EnvironmentsCommand
    router.match match_regexp(/^lock #{ENV} on #{REPO}(:(?<message>.*(?<!\!$)))?(?<force>!)?$/), LockCommand
    router.match match_regexp(/^unlock all$/), UnlockAllCommand
    router.match match_regexp(/^unlock #{ENV} on #{REPO}$/), UnlockCommand
    router.match match_regexp(/^check #{ENV} on #{REPO}$/), CheckCommand
    router.match match_regexp(/^boom$/), BoomCommand
    router.match match_regexp(/^#{REPO}(@#{REF})?( to #{ENV})?(?<force>!)?$/), DeployCommand
    router.match match_regexp(/^latest #{REPO}( to #{ENV})?$/), LatestCommand

    router.not_found = -> (env) do
      env['params'] = { 'not_found' => true }
      HelpCommand.call(env)
    end

    router
  end

  def self.build
    new route
  end

  # Returns a Slash::Matcher::Regexp matcher that will also normalize the
  # `repository` param to include the full name of the repository, if the user
  # specifies the short form.
  def self.match_regexp(re)
    matcher = Slash.match_regexp(re)
    RepositoryMatcher.new(matcher)
  end

  def initialize(router)
    @router = router
  end

  def call(env)
    account = env['account']
    user = account.user

    # User needs a Github account, so bubble MissingGitHubAccount if missing.
    user.github_account

    scope = {
      person: { id: user.id, username: user.username }
    }

    Rollbar.scoped(scope) do
      begin
        router.call(env)
      rescue SlashDeploy::RepoUnauthorized => e
        Slash.reply UnauthorizedMessage.build \
          repository: e.repository
      rescue StandardError => e
        Rollbar.error(e)
        raise e if Rails.env.test?
        Slash.reply ErrorMessage.build
      end
    end
  end
end
