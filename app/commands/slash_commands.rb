# SlashCommands is a slash handler that provides the SlashDeploy slack slash
# commands. This class simply a demuxer that routes requests to the appropriate
# sub command.
class SlashCommands
  include SlashDeploy::Commands::Rendering

  # Should never be raised outside of this class.
  InvalidRepository = Class.new(StandardError)

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
  # rubocop:disable Metrics/CyclomaticComplexity
  def route(slack_user, cmd)
    repo = /(?<repository>\S+?)/
    env  = /(?<environment>\S+?)/
    ref  = /(?<ref>\S+?)/

    case cmd.request.text
    when /^help$/
      [help, {}]
    when /^where #{repo}$/
      [environments, params(slack_user, Regexp.last_match)]
    when /^lock #{env} on #{repo}(:(?<message>.*))?$/
      [lock, params(slack_user, Regexp.last_match)]
    when /^unlock #{env} on #{repo}$/
      [unlock, params(slack_user, Regexp.last_match)]
    when /^boom$/
      [boom, {}]
    when /^#{repo}(@#{ref})?( to #{env})?(?<force>!)?$/
      [deploy, params(slack_user, Regexp.last_match)]
    else
      [help, 'not_found' => true]
    end
  rescue InvalidRepository
    [help, {}]
  end

  def call(env)
    cmd  = env['cmd']
    user = env['user']
    team = SlackTeam.find_or_initialize_by(id: cmd.request.team_id) do |t|
      t.domain = cmd.request.team_domain
    end
    slack_user = SlackUser.new(user, team)

    scope = {
      person: { id: user.id, username: user.username }
    }

    Rollbar.scoped(scope) do
      begin
        handler, params = route(slack_user, cmd)
        handler.run(slack_user, cmd, params)
      rescue SlashDeploy::RepoUnauthorized => e
        reply :unauthorized, repository: e.repository
      rescue StandardError => e
        Rollbar.error(e)
        reply :error
      end
    end
  end

  private

  def params(slack_user, matches)
    p = Hash[matches.names.zip(matches.captures)]

    # Coerce the repository param to include this slack teams default github org.
    if p['repository'].present? && !p['repository'].include?('/')
      team = slack_user.slack_team
      if team.github_organization.present?
        p['repository'] = "#{team.github_organization}/#{p['repository']}"
      else
        # At this point it's not a valid repository (missing owner), return the help.
        fail InvalidRepository
      end
    end

    p
  end
end
