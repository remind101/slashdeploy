require 'slash'
require 'slack'
require 'hookshot'
require 'github'
require 'slack'
require 'perty'

require 'slashdeploy/errors'

# SlashDeployer is the core API of the SlashDeploy service.
module SlashDeploy
  # Matches a GitHub repo
  # http://rubular.com/r/W1ebnRsMEh
  GITHUB_REPO_REGEX = %r{([\w\-]+)\/([\w\-]+)}

  autoload :Service, 'slashdeploy/service'
  autoload :State,   'slashdeploy/state'
  autoload :Auth,    'slashdeploy/auth'

  module Deployers
    autoload :CircleCI, 'slashdeploy/deployers/circleci'
  end

  class << self
    attr_accessor :state

    def deployer_for(target)
      case target.to_sym
      when :circleci
        Deployers::CircleCI.build
      else
        raise "No Deployer for #{target}"
      end
    end

    def service
      @service ||= Service.new
    end

    # Returns a Rack app for handling the slack slash commands.
    def commands_handler
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

    def slack_commands
      # Adapt it to rack.
      Slash::Rack.new(commands_handler)
    end

    def actions_handler
      handler = SlashActions.build

      # Log the request
      handler = Slash::Middleware::Logging.new(handler)

      # Ensure that users are authorized
      handler = Auth.new(handler, Rails.configuration.x.oauth.github, ::SlashDeploy.state)

      # Verify that the slash command came from slack.
      Slash::Middleware::Verify.new(handler, Rails.configuration.x.slack.verification_token)
    end

    def slack_actions
      Slash::Rack.new(actions_handler)
    end
  end
end
