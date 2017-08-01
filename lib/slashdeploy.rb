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
  # http://rubular.com/r/Ecpz7KLRyE
  GITHUB_REPO_REGEX = %r{([\w\-]+)\/([\w\-\.]+)}

  autoload :Service, 'slashdeploy/service'
  autoload :Auth,    'slashdeploy/auth'

  def self.github_app
    @github_app ||= GitHub::App.build(Rails.configuration.x.github_app_id, Rails.configuration.x.github_app_private_pem)
  end

  # Returns a Rack app for handling the slack slash commands.
  def self.commands_handler
    handler = SlashCommands.build

    # Log the request
    handler = Slash::Middleware::Logging.new(handler)

    # Ensure that users are authorized
    handler = Auth.new(handler, Rails.configuration.x.state_key)

    # Strip extra whitespace from the text.
    handler = Slash::Middleware::NormalizeText.new(handler)

    # Verify that the slash command came from slack.
    Slash::Middleware::Verify.new(handler, Rails.configuration.x.slack.verification_token)
  end

  def self.slack_commands
    # Adapt it to rack.
    Slash::Rack.new(commands_handler)
  end

  def self.actions_handler
    handler = SlashActions.build

    # Log the request
    handler = Slash::Middleware::Logging.new(handler)

    # Ensure that users are authorized
    handler = Auth.new(handler, Rails.configuration.x.state_key)

    # Verify that the slash command came from slack.
    Slash::Middleware::Verify.new(handler, Rails.configuration.x.slack.verification_token)
  end

  def self.slack_actions
    Slash::Rack.new(actions_handler)
  end

  class << self
    attr_accessor :state

    def service
      @service ||= Service.new
    end
  end
end
