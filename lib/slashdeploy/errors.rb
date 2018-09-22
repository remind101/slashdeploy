module SlashDeploy
  Error = Class.new(StandardError)

  EnvironmentAutoDeploys = Class.new(Error)

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
end
