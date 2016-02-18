require 'slash'
require 'hookshot'
require 'github'
require 'perty'

require 'slashdeploy/errors'

# SlashDeployer is the core API of the SlashDeploy service.
module SlashDeploy
  # Matches a GitHub repo
  # http://rubular.com/r/W1ebnRsMEh
  GITHUB_REPO_REGEX = %r{[\w\-]+\/[\w\-]+}

  autoload :Service, 'slashdeploy/service'
  autoload :State,   'slashdeploy/state'

  # Rack apps for handling slash commands.
  module Commands
    autoload :Auth,      'slashdeploy/commands/auth'
    autoload :Rendering, 'slashdeploy/commands/rendering'

    # Returns a Rack app for handling the slack slash commands.
    def self.slack_handler
      handler = SlashCommands.build

      # Log the request
      handler = Slash::Middleware::Logging.new(handler)

      # Ensure that users are authorized
      handler = Auth.new(handler, Rails.configuration.x.oauth.github, ::SlashDeploy.state)

      # Strip extra whitespace from the text.
      handler = Slash::Middleware::NormalizeText.new(handler)

      # Verify that the slash command came from slack.
      Slash::Middleware::Verify.new(handler, Rails.configuration.x.slack.verification_token)
    end

    def self.slack
      # Adapt it to rack.
      Slash::Rack.new(slack_handler)
    end
  end

  class << self
    attr_accessor :state

    def service
      @service ||= Service.new
    end

    def slack_commands
      Commands.slack
    end

    def github_webhooks
      router = Hookshot::Router.new
      router.handle :push,   PushEvent
      router.handle :status, StatusEvent
      router
    end

    def app
      Rails.application
    end
  end
end
