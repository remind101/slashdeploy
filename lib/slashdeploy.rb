require 'slash'

# SlashDeployer is the core API of the SlashDeploy service.
module SlashDeploy
  # Matches a GitHub repo
  # http://rubular.com/r/W1ebnRsMEh
  GITHUB_REPO_REGEX = %r{[\w\-]+\/[\w\-]+}

  autoload :Service, 'slashdeploy/service'
  autoload :State,   'slashdeploy/state'

  # Authorizer is used to check if the user has access to a repo.
  module Authorizer
    autoload :GitHub, 'slashdeploy/authorizer/github'
    autoload :Fake,   'slashdeploy/authorizer/fake'

    def self.new(kind)
      case kind.try(:to_sym)
      when :github
        GitHub.new
      else
        Fake.new
      end
    end
  end

  # Deployer represents something that can create a new deployment request.
  module Deployer
    autoload :GitHub, 'slashdeploy/deployer/github'
    autoload :Fake,   'slashdeploy/deployer/fake'

    def self.new(kind)
      case kind.try(:to_sym)
      when :github
        GitHub.new
      else
        Fake.new
      end
    end
  end

  # Rack apps for handling slash commands.
  module Commands
    autoload :Auth,      'slashdeploy/commands/auth'
    autoload :Rendering, 'slashdeploy/commands/rendering'

    # Returns a Rack app for handling the slack slash commands.
    def self.slack_handler
      handler = SlashCommands.build

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

  Error = Class.new(StandardError)

  # Raised when a user doesn't have access to the given repo.
  class RepoUnauthorized < Error
    attr_reader :repository

    def initialize(repo)
      @repository = repo
    end
  end

  # Raised when an action cannot be performed on the environment because it's locked.
  class EnvironmentLockedError < Error
    attr_reader :lock

    def initialize(lock)
      @lock = lock
    end
  end

  # RedCommitError is an error that's returned when the commit someone is
  # trying to deploy is not green.
  class RedCommitError < Error
    attr_reader :contexts

    def initialize(contexts = [])
      @contexts = contexts
    end

    def failing_contexts
      contexts.select(&:bad?)
    end
  end

  class << self
    attr_accessor :state

    def service
      @service ||= Service.new
    end

    def app
      Rails.application
    end
  end
end
