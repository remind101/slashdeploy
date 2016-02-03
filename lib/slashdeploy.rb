# SlashDeployer is the core API of the SlashDeploy service.
module SlashDeploy
  autoload :Service, 'slashdeploy/service'
  autoload :State,   'slashdeploy/state'

  # Deployer represents something that can create a new deployment request.
  module Deployer
    autoload :GitHub, 'slashdeploy/deployer/github'
    autoload :Fake,   'slashdeploy/deployer/fake'
  end

  # Rack apps for handling slash commands.
  module Commands
    autoload :Auth, 'slashdeploy/commands/auth'

    # Returns a Rack app for handling the slack slash commands.
    def self.slack_handler
      handler = SlashCommands.new(::SlashDeploy.service)

      # Ensure that users are authorized
      handler = Auth.new(handler, Rails.configuration.x.oauth.github, ::SlashDeploy.state)

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

    def app
      Rack::Builder.app do
        # Slack will post slash commands here.
        map '/commands' do
          run SlashDeploy::Commands.slack
        end

        map '/' do
          run Rails.application
        end
      end
    end
  end
end
