# GithubEventHandler is a base GitHub event handler. All GitHub event handler
# should inherit from this.
class GithubEventHandler
  attr_reader :env
  attr_reader :slashdeploy

  UnknownRepository = Class.new(SlashDeploy::Error)

  def self.call(env)
    new(env, ::SlashDeploy.service).call
  end

  def initialize(env, slashdeploy)
    @env = env
    @slashdeploy = slashdeploy
  end

  def call
    env['rack.input'] = StringIO.new env['rack.input'].read
    req = ::Rack::Request.new env
    @event = JSON.parse req.body.read
    req.body.rewind # rewind body so downstream can re-read.

    repo_name = @event['repository']['full_name']
    @repository = Repository.find_by(name: repo_name)
    fail(UnknownRepository, "Received GitHub webhook for unknown repository: #{repo_name}") unless @repository
    return [403, {}, ['']] unless Hookshot.verify(req, @repository.github_secret)

    scope = {
      repository: @repository.name,
      event: @event
    }
    Rollbar.scoped(scope) do
      run
    end

    [200, {}, ['']]
  end

  def run
    fail NotImplementedError
  end

  private

  attr_reader :repository
  attr_reader :event

  delegate :transaction, to: :'ActiveRecord::Base'
end
