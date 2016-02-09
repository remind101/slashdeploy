# SlashCommands is a slash handler that provides the SlashDeploy slack slash
# commands. This class simply a demuxer that routes requests to the appropriate
# sub command.
class SlashCommands
  include SlashDeploy::Commands::Rendering

  attr_reader \
    :help,
    :deploy,
    :environments,
    :lock,
    :unlock,
    :boom

  def initialize(slashdeploy)
    @help = HelpCommand.new slashdeploy
    @deploy = DeployCommand.new slashdeploy
    @environments = EnvironmentsCommand.new slashdeploy
    @lock = LockCommand.new slashdeploy
    @unlock = UnlockCommand.new slashdeploy
    @boom = BoomCommand.new slashdeploy
  end

  # Route returns the handler that should handle the request.
  def route(cmd)
    repo = /(?<repository>#{SlashDeploy::GITHUB_REPO_REGEX})/
    env  = /(?<environment>\S+?)/
    ref  = /(?<ref>\S+?)/

    case cmd.request.text
    when /^help$/
      [help, {}]
    when /^where #{repo}$/
      [environments, params(Regexp.last_match)]
    when /^lock #{env} on #{repo}(:(?<message>.*))?$/
      [lock, params(Regexp.last_match)]
    when /^unlock #{env} on #{repo}$/
      [unlock, params(Regexp.last_match)]
    when /^#{repo}(@#{ref})?( to #{env})?(?<force>!)?$/
      [deploy, params(Regexp.last_match)]
    when /^boom$/
      [boom, {}]
    else
      [help, 'not_found' => true]
    end
  end

  def call(env)
    cmd  = env['cmd']
    user = env['user']

    handler, params = route(cmd)
    handler.run(user, cmd, params)
  rescue SlashDeploy::RepoUnauthorized => e
    reply :unauthorized, repository: e.repository
  rescue StandardError => e
    Rollbar.error(e)
    reply :error
  end

  private

  def params(matches)
    Hash[matches.names.zip(matches.captures)]
  end
end
