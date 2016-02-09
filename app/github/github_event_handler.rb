# GithubEventHandler is a base GitHub event handler. All GitHub event handler
# should inherit from this.
class GithubEventHandler
  attr_reader :slashdeploy

  UnknownRepository = Class.new(SlashDeploy::Error)

  def initialize(slashdeploy)
    @slashdeploy = slashdeploy
  end

  def call(env)
    env['rack.input'] = StringIO.new env['rack.input'].read
    req = ::Rack::Request.new env
    event = JSON.parse req.body.read
    req.body.rewind # rewind body so downstream can re-read.

    repo_name = event['repository']['full_name']
    repo = Repository.find_by(name: repo_name)
    fail(UnknownRepository, "Received GitHub webhook for unknown repository: #{repo_name}") unless repo
    return [403, {}, ['']] unless Hookshot.verify(req, repo.github_secret)

    run(repo, event)

    [200, {}, ['']]
  end

  def run(_repository, _event)
    fail NotImplementedError
  end

  private

  delegate :transaction, to: :'ActiveRecord::Base'
end
