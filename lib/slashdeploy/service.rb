module SlashDeploy
  # SlashDeploy::Service provides the core internal API for controllers to
  # consume. This composes the various backends and provides a very simple API
  # for performing actions.
  class Service
    # An object that responds to `call` where the first argument is a User
    # object. Should return something that implements the Deployer interface.
    attr_accessor :deployer

    # Creates a new deployment request as the given user.
    #
    # req - DeploymentRequest object.
    #
    # Returns the id of the created Deployment.
    def create_deployment(user, req)
      req = DeploymentRequest.new(
        repository: req.repository,
        environment: req.environment || config.default_environment,
        ref: req.ref || config.default_ref
      )

      # Check if the environment we're deploying to is locked.
      lock = Lock.for_environment(req.repository, req.environment)
      if lock
        fail EnvironmentLockedError, lock
      else
        deployer = self.deployer.call(user)
        Environment.used(req.repository, req.environment)
        deployer.create_deployment(req)
        req
      end
    end

    # Returns the known environments that this repository can be deployed to.
    #
    # repository - The name of the repository.
    #
    # Returns an Array of Environments
    def environments(_user, repository)
      # TODO: Authorize that this user has access to the repository.
      Environment.where(repository: repository)
    end

    # Attempts to lock the repository on the repo.
    #
    # req - A LockRequest.
    #
    # Returns a Lock.
    def lock_environment(_user, req)
      # TODO: Authorize that this user has access to the repository.
      env = Environment.find_or_create_by(repository: req.repository, name: req.environment)
      env.lock! req.message
    end

    # Unlocks an environment.
    #
    # req - An UnlockRequest.
    #
    # Returns nothing
    def unlock_environment(_user, req)
      # TODO: Authorize that this user has access to the repository.
      lock = Lock.for_environment(req.repository, req.environment)
      return unless lock
      lock.update_attributes(active: false)
    end

    private

    def config
      Rails.configuration.x
    end
  end
end
