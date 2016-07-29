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
    def direct_message(user, klass, attributes = {})
      user.slack_accounts.each do |account|
        message = klass.build attributes.merge(account: account)
        slack.direct_message(account, message)
      end
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

    # Used to track when a commit status context changes state. If there are
    # active auto deployments for the given sha, they may be deployed.
    def track_commit_status_context_change(sha, commit_status_context)
      auto_deployment = AutoDeployment.active.find_by(sha: sha)
      return unless auto_deployment
      failed = auto_deployment.context_state commit_status_context
      if failed
        auto_deployment.user.slack_accounts.each do |account|
          message = AutoDeploymentFailedMessage.build \
            account: account,
            auto_deployment: auto_deployment,
            commit_status_context: commit_status_context
          slack.direct_message(account, message)
        end
      end
      auto_deploy auto_deployment if auto_deployment.ready?
    end

    # Creates a new AutoDeployment for the given sha.
    #
    # environment - Environment to deploy to.
    # sha         - Git sha to deploy.
    # user        - The User to attribute the deployment to.
    #
    # Returns an AutoDeployment.
    def create_auto_deployment(environment, sha, user)
      existing = environment.active_auto_deployment
      if existing
        # This can happen if the user triggers the webhook manually.
        return existing if existing.sha == sha

        # If this environment has an existing active auto deployment, we'll
        # cancel it before starting this auto deployment. We do this to prevent
        # race conditions where commit status events for an older auto deployment
        # could come in late.
        existing.cancel!
      end

      auto_deployment = environment.auto_deployments.create! user: user, sha: sha
      user.slack_accounts.each do |account|
        message = AutoDeploymentCreatedMessage.build \
          account: account,
          auto_deployment: auto_deployment
        slack.direct_message(account, message)
      end
      auto_deploy auto_deployment if auto_deployment.ready?
      auto_deployment
    end

    private

    # Triggers an auto deployment if the AutoDeployment is ready.
    #
    # auto_deployment - An AutoDeployment.
    #
    # Returns nothing.
    def auto_deploy(auto_deployment)
      fail "auto_deploy called on AutoDeployment that's not ready: #{auto_deployment.id}" unless auto_deployment.ready?

      begin
        user = auto_deployment.user
        environment = auto_deployment.environment

        # Check if the environment we're deploying to is locked.
        github.create_deployment(
          user,
          deployment_request(environment, auto_deployment.sha)
        ) unless environment.locked?

        user.slack_accounts.each do |account|
          k = environment.locked? ? AutoDeploymentEnvironmentLockedMessage : AutoDeploymentStartedMessage
          message = k.build \
            account: account,
            auto_deployment: auto_deployment
          slack.direct_message(account, message)
        end
      ensure
        auto_deployment.done!
      end
    end

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
