module SlashDeploy
  # SlashDeploy::Service provides the core internal API for controllers to
  # consume. This composes the various backends and provides a very simple API
  # for performing actions.
  class Service
    # Client for interacting with GitHub.
    attr_accessor :github

    # Client for interacting with Slack.
    attr_accessor :slack

    def authorize!(user, repository)
      fail RepoUnauthorized, repository unless github.access?(user, repository.to_s)
    end

    # Sends a direct message to all of the users slack accounts.
    def direct_message(account, klass, attributes = {})
      message = klass.build attributes.merge(account: account)
      slack.direct_message(account, message)
    end

    # Creates a new AutoDeployment for the given sha.
    #
    # environment - Environment to deploy to.
    # sha         - Git sha to deploy.
    # user        - The User to attribute the deployment to.
    #
    # Returns an AutoDeployment.
    def create_auto_deployment(environment, sha, user)
      auto_deployment = environment.auto_deployments.create! user: user, sha: sha
      if auto_deployment.ready?
        auto_deploy auto_deployment
      else
        direct_message user.slack_account_for_github_organization(environment.repository.organization), AutoDeploymentCreatedMessage, auto_deployment: auto_deployment
      end
      auto_deployment
    end

    # Creates a new deployment request as the given user.
    #
    # user        - The User requesting the deployment.
    # environment - The Environment to be deployed to.
    # ref         - A String git ref. If none is provided, defaults to the
    #               default ref.
    # options     - A Hash of extra options.
    #               :force       - "force" the deployment, ignoring commit
    #                               status contexts.
    #               :strong_lock - If set to true, even the user that locked it
    #                              won't be able to deploy.
    #
    # Returns a DeploymentResponse.
    def create_deployment(user, environment, ref = nil, options = {})
      authorize! user, environment.repository.to_s

      req = deployment_request(environment, ref, force: options[:force])

      # Check if the environment we're deploying to is configured for auto deployments.
      fail EnvironmentAutoDeploys if environment.auto_deploy_enabled? && !options[:force]

      # Check if the environment we're deploying to is locked.
      lock = environment.active_lock
      if lock && lock.user != user
        fail EnvironmentLockedError, lock
      else
        last_deployment = github.last_deployment(user, req.repository, req.environment)
        deployment = github.create_deployment(user, req)
        DeploymentResponse.new(deployment: deployment, last_deployment: last_deployment)
      end
    end

    # Attempts to lock the environment on the repo.
    #
    # environment - An Environment to lock.
    # options     - A hash of options.
    #               :message - An optional message.
    #               :force   - Steal the lock if the environment is already locked.
    #
    # Returns a Lock.
    def lock_environment(user, environment, options = {})
      authorize! user, environment.repository

      lock = environment.active_lock

      if lock
        return if lock.user == user # Already locked, nothing to do.
        fail EnvironmentLockedError, lock unless options[:force]
        lock.unlock!
      end

      stolen = lock
      lock = environment.lock! user, options[:message]

      LockResponse.new \
        lock: lock,
        stolen: stolen
    end

    # Attempts to queue the user for the environment lock.
    # Throws an error if there is no active lock for the environment.
    #
    # environment - An Environment to lock.
    # options     - A hash of options.
    #               :message - An optional message.
    #
    # Returns a waiting Lock or Nil, if the user is already queued.
    def queue_user_for_environment(user, environment, options = {})
      authorize! user, environment.repository

      fail EnvironmentUnlockedError, 'no active lock' unless environment.locked?

      return if environment.has_waiting_user?(user)
      position = environment.queue! user, options[:message]
      position
    end

    # Attempts to lock the environment for the next in line.
    # Throws an error if the environment is still locked.
    #
    # environment - An Environment to lock.
    # Returns a Lock, the new active one, or nil if no one is in queue.
    def give_lock_to_next_user(environment)
      fail EnvironmentLockedError, 'already locked' if environment.locked?

      lock = environment.next_in_line
      return unless lock.present?

      lock.dequeue!
      lock.lock!
      lock
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

    # Triggers an auto deployment if the AutoDeployment is ready.
    #
    # auto_deployment - An AutoDeployment.
    #
    # Returns nothing.
    def auto_deploy(auto_deployment)
      fail "auto_deploy called on AutoDeployment that's not ready: #{auto_deployment.id}" unless auto_deployment.ready?

      begin
        environment = auto_deployment.environment

        # Check if the environment we're deploying to is locked.
        return if environment.locked?
        github.create_deployment(
          auto_deployment.user,
          deployment_request(environment, auto_deployment.sha)
        )
      ensure
        auto_deployment.done!
      end
    end

    # Creates a MessageAction, generating a uuid for the callback_id
    #
    #  action - The class that the message action will execute. Implements BaseAction.
    #  options - params hash that will be passed to the command
    #
    #  Returns a MessageAction
    def create_message_action(action, options = {})
      MessageAction.create!(
        callback_id: SecureRandom.uuid,
        action_params: options.to_json,
        action: action.name
      )
    end

    private

    def deployment_request(environment, ref, options = {})
      DeploymentRequest.new(
        repository:  environment.repository.to_s,
        environment: environment.to_s,
        ref:         ref || environment.default_ref,
        force:       options[:force]
      )
    end
  end
end
