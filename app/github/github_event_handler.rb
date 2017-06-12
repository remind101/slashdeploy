# GitHubEventHandler is a base GitHub event handler. All GitHub event handler
# should inherit from this.
class GitHubEventHandler
  attr_reader :env
  attr_reader :slashdeploy

  UnknownRepository = Class.new(SlashDeploy::Error)

  def self.call(env)
    new(env, ::SlashDeploy.service, Rails.configuration.x.integration_secret).call
  end

  def initialize(env, slashdeploy, secret = nil)
    @env = env
    @slashdeploy = slashdeploy
    @secret = secret
  end

  def installation?
    event['installation'].present?
  end

  def installation
    event['installation']['id']
  end

  def integration_secret?
    @secret.present?
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

        # Just a sanity check to make sure all webhooks are from an
        # integration.
        fail StandardError, 'Not an installation' unless installation?
        fail StandardError, 'No integration secret set' unless integration_secret?

        # When the webhook comes from an installation, we'll verify the
        # request using a global secret, then create the repository if
        # needed. This is done to support installing SlashDeploy
        # organization wide.
        return [403, {}, ['']] unless Hookshot.verify(req, @secret)
        @repository = Repository.with_name(repo_name)

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
