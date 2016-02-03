# SlashCommands is a slash handler that provides the SlashDeploy slack slash
# commands. This class simply a demuxer that routes requests to the appropriate
# sub command.
class SlashCommands
  attr_reader :help, :deploy, :environments

  def initialize(slashdeploy)
    @help = HelpCommand.new slashdeploy
    @deploy = DeployCommand.new slashdeploy
    @environments = EnvironmentsCommand.new slashdeploy
  end

  # Route returns the handler that should handle the request.
  #
  # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
  def route(cmd)
    case cmd.request.text
    when /^help$/
      [help, {}]
    when /^where (?<repository>\S+?)$/
      [environments, params(Regexp.last_match)]
    when /^(?<repository>\S+?)@(?<ref>\S+?) to (?<environment>\S+?)$/
      [deploy, params(Regexp.last_match)]
    when /^(?<repository>\S+?) to (?<environment>\S+?)$/
      [deploy, params(Regexp.last_match)]
    when /^(?<repository>\S+?)@(?<ref>\S+?)$/
      [deploy, params(Regexp.last_match)]
    when /^(?<repository>\S+?)$/
      [deploy, params(Regexp.last_match)]
    end
  end

  def call(env)
    cmd  = env['cmd']
    user = env['user']

    handler, params = route(cmd)
    handler.run(user, cmd, params)
  end

  private

  def params(matches)
    Hash[matches.names.zip(matches.captures)]
  end
end
