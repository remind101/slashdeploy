# SlashCommands is a slash handler that provides the SlashDeploy slack slash
# commands. This class simply a demuxer that routes requests to the appropriate
# sub command.
class SlashCommands
  REPO = /(?<repository>\S+?)/
  ENV  = /(?<environment>\S+?)/
  REF  = /(?<ref>\S+?)/

  attr_reader :router

  def self.route
    router = Slash::Router.new
    router.match match_regexp(/^help$/), HelpCommand
    router.match match_regexp(/^where #{REPO}$/), EnvironmentsCommand
    router.match match_regexp(/^lock #{ENV} on #{REPO}(:(?<message>.*(?<!\!$)))?(?<force>!)?$/), LockCommand
    router.match match_regexp(/^unlock #{ENV} on #{REPO}$/), UnlockCommand
    router.match match_regexp(/^boom$/), BoomCommand
    router.match match_regexp(/^#{REPO}(@#{REF})?( to #{ENV})?(?<force>!)?$/), DeployCommand

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

  # Authenticates the user, then delegates to the router.
  def call(env)
    cmd  = env['cmd']
    user = User.find_by_slack(cmd.request.user_id)
    if user
      team = SlackTeam.find_or_initialize_by(id: cmd.request.team_id) do |t|
        t.domain = cmd.request.team_domain
      end
      env['user'] = SlackUser.new(user, team)

      scope = {
        person: { id: user.id, username: user.username }
      }

      Rollbar.scoped(scope) do
        begin
          router.call(env)
        rescue SlashDeploy::RepoUnauthorized => e
          Slash.reply UnauthorizedMessage.build \
            repository: e.repository
        rescue User::MissingGitHubAccount => e
          Slash.reply(Slack::Message.new(text: "Please link a GitHub account first."))
        rescue StandardError => e
          Rollbar.error(e)
          raise e if Rails.env.test?
          Slash.reply ErrorMessage.build
        end
      end
    else
      Slash.reply(Slack::Message.new(text: "Please <#{}|login> first."))
    end
  end
end
