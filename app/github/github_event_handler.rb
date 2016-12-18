# GitHubEventHandler is a base GitHub event handler. All GitHub event handler
# should inherit from this.
class GitHubEventHandler
  attr_reader :env
  attr_reader :slashdeploy

  UnknownRepository = Class.new(SlashDeploy::Error)

  def self.call(env)
    new(env, ::SlashDeploy.service, ENV['GITHUB_WEBHOOK_SECRET']).call
  end

  def initialize(env, slashdeploy, secret = nil)
    @env = env
    @slashdeploy = slashdeploy
    @secret = secret
  end

  def call
    logger.with_module('github event') do
      logger.with_module(self.class) do
        env['rack.input'] = StringIO.new env['rack.input'].read
        req = ::Rack::Request.new env
        @event = JSON.parse req.body.read
        req.body.rewind # rewind body so downstream can re-read.

        repo_name = @event['repository']['full_name']

        logger.info("repository=#{repo_name}")

        @repository = Repository.find_by(name: repo_name)
        unless @repository
          logger.info("repository doesn't exist in SlashDeploy")
          fail(UnknownRepository, "Received GitHub webhook for unknown repository: #{repo_name}")
        end

        if event['installation']
          return [403, {}, ['']] unless Hookshot.verify(req, @secret)
        else
          return [403, {}, ['']] unless Hookshot.verify(req, @repository.github_secret)
        end

        scope = {
          event: @event,
          repository: @repository.name
        }
        Rollbar.scoped(scope) do
          run
        end

        [200, {}, ['']]
      end
    end
  end

  def run
    fail NotImplementedError
  end

  private

  def logger
    Rails.logger
  end

  attr_reader :repository
  attr_reader :event

  delegate :transaction, to: :'ActiveRecord::Base'
end
