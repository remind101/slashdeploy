module SlashDeploy
  # SlashDeploy::Service provides the core internal API for controllers to
  # consume. This composes the various backends and provides a very simple API
  # for performing actions.
  class Service
    # An object that responds to `call` where the first argument is a User
    # object. Should return something that implements the Deployer interface.
    attr_accessor :deployer

    # A SlashDeploy::Authorizer implementation, which will be used to ensure
    # that the user has permissions to perform actions against a repository.
    attr_accessor :authorizer

    # Creates a new deployment request as the given user.
    #
    # req - DeploymentRequest object.
    #
    # Returns the id of the created Deployment.
    def create_deployment(user, req)
      req = DeploymentRequest.new(
        repository: req.repository,
        environment: req.environment || config.default_environment,
        ref: req.ref || config.default_ref,
        force: req.force
      )

      # Check if the environment we're deploying to is locked.
      transaction do
        repo = Repository.with_name(req.repository)
        env  = repo.environment(req.environment)
        lock = env.active_lock
        if lock && lock.user != user
          fail EnvironmentLockedError, lock
        else
          deployer.create_deployment(user, req)
        end
      end
    end

    # Returns the known environments that this repository can be deployed to.
    #
    # repository - The name of the repository.
    #
    # Returns an Array of Environments
    def environments(user, repository)
      authorize! user, repository

      repo = Repository.with_name(repository)
      repo.environments
    end

    # Attempts to lock the repository on the repo.
    #
    # req - A LockRequest.
    #
    # Returns a Lock.
    def lock_environment(user, req)
      authorize! user, req.repository

      transaction do
        repo = Repository.with_name(req.repository)
        env  = repo.environment(req.environment)
        lock = env.active_lock

        if lock
          return if lock.user == user # Already locked, nothing to do.
          lock.unlock!
        end

        stolen = lock
        lock = env.lock! user, req.message

        LockResponse.new \
          lock: lock,
          stolen: stolen
      end
    end

    # Unlocks an environment.
    #
    # req - An UnlockRequest.
    #
    # Returns nothing
    def unlock_environment(user, req)
      authorize! user, req.repository

      transaction do
        repo = Repository.find_or_create_by(name: req.repository)
        env  = repo.environments.find_or_create_by(name: req.environment)
        lock = env.active_lock
        return unless lock
        lock.update_attributes(active: false)
      end
    end

    private

    def authorize!(user, repository)
      fail RepoUnauthorized, repository unless authorizer.authorized?(user, repository)
    end

    def transaction(*args, &block)
      ActiveRecord::Base.transaction(*args, &block)
    end

    def config
      Rails.configuration.x
    end
  end
end
