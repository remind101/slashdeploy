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
    # user        - The User requesting the deployment.
    # environment - The Environment to be deployed to.
    # ref         - A String git ref. If none is provided, defaults to the
    #               default ref.
    # options     - A Hash of extra options.
    #               :force - "force" the deployment, ignoring commit status contexts.
    #
    # Returns a DeploymentResponse.
    def create_deployment(user, environment, ref = nil, options = {})
      repository = environment.repository

      req = DeploymentRequest.new(
        repository:  repository.to_s,
        environment: environment.to_s,
        ref:         ref || environment.default_ref,
        force:       options[:force]
      )

      # Check if the environment we're deploying to is locked.
      lock = environment.active_lock
      if lock && lock.user != user
        fail EnvironmentLockedError, lock
      else
        deployer.create_deployment(user, req)
      end
    end

    # Returns the known environments that this repository can be deployed to.
    #
    # repository - The name of the repository.
    #
    # Returns an Array of Environments
    def environments(user, repository)
      authorize! user, repository
      repository.environments
    end

    # Attempts to lock the environment on the repo.
    #
    # environment - An Environment to lock.
    # message     - An option message.
    #
    # Returns a Lock.
    def lock_environment(user, environment, message = nil)
      authorize! user, environment.repository

      lock = environment.active_lock

      if lock
        return if lock.user == user # Already locked, nothing to do.
        lock.unlock!
      end

      stolen = lock
      lock = environment.lock! user, message

      LockResponse.new \
        lock: lock,
        stolen: stolen
    end

    # Unlocks an environment.
    #
    # environment - An Environment to unlock
    #
    # Returns nothing
    def unlock_environment(user, environment)
      authorize! user, environment.repository

      lock = environment.active_lock
      return unless lock
      lock.unlock!
    end

    private

    def authorize!(user, repository)
      fail RepoUnauthorized, repository unless authorizer.authorized?(user, repository.to_s)
    end
  end
end
