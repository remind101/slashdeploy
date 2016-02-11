# SlashCommands is a slash handler that provides the SlashDeploy slack slash
# commands. This class simply a demuxer that routes requests to the appropriate
# sub command.
class SlashCommands
  include SlashDeploy::Commands::Rendering

  REPO = /(?<repository>\S+?)/
  ENV  = /(?<environment>\S+?)/
  REF  = /(?<ref>\S+?)/

  attr_reader :router

  def self.route(slashdeploy)
    help         = HelpCommand.new slashdeploy
    environments = EnvironmentsCommand.new slashdeploy
    lock         = LockCommand.new slashdeploy
    unlock       = UnlockCommand.new slashdeploy
    deploy       = DeployCommand.new slashdeploy
    boom         = BoomCommand.new slashdeploy

    router = Slash::Router.new
    router.match match_regexp(/^help$/), help
    router.match match_regexp(/^where #{REPO}$/), environments
    router.match match_regexp(/^lock #{ENV} on #{REPO}(:(?<message>.*))?$/), lock
    router.match match_regexp(/^unlock #{ENV} on #{REPO}$/), unlock
    router.match match_regexp(/^boom$/), boom
    router.match match_regexp(/^#{REPO}(@#{REF})?( to #{ENV})?(?<force>!)?$/), deploy

    router.not_found = -> (env) do
      env['params'] = { 'not_found' => true }
      help.call(env)
    end

    router
  end

  def self.build(slashdeploy)
    new route(slashdeploy)
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
    user = env['user']

    scope = {
      person: { id: user.id, username: user.username }
    }

    Rollbar.scoped(scope) do
      begin
        router.call(env)
      rescue SlashDeploy::RepoUnauthorized => e
        reply :unauthorized, repository: e.repository
      rescue StandardError => e
        Rollbar.error(e)
        raise e if Rails.env.test?
        reply :error
      end
    end
  end
end
