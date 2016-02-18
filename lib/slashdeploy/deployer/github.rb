module SlashDeploy
  module Deployer
    # GitHub implements the Deployer interface backed by the github API.
    class GitHub
      # Creates a new deployment request on github.
      def create_deployment(user, req)
        options = {
          environment: req.environment,
          auto_merge: false,
          task: 'deploy'
        }
        options[:required_contexts] = [] if req.force

        last_github_deployment = last_deployment_to(user.octokit_client, req.repository, req.environment)
        github_deployment = user.octokit_client.create_deployment(req.repository, req.ref, options)

        DeploymentResponse.new(
          deployment:      deployment_from_github(req.repository, github_deployment),
          last_deployment: last_github_deployment
        )
      rescue Octokit::Conflict => e
        error = required_contexts_error(e.errors)
        raise RedCommitError, commit_status_contexts(error[:contexts]) if error
        raise
      end

      private

      def last_deployment_to(client, repository, environment)
        deployments = client.deployments(repository, environment: environment)
        return if deployments.empty?
        deployment_from_github repository, deployments.first
      end

      def deployment_from_github(repository, github_deployment)
        Deployment.new(
          id:          github_deployment.id,
          repository:  repository,
          ref:         github_deployment.ref,
          sha:         github_deployment.sha,
          environment: github_deployment.environment
        )
      end

      def required_contexts_error(errors)
        errors.find { |err| err[:field] == 'required_contexts' }
      end

      def commit_status_contexts(hash)
        hash.map { |h| CommitStatusContext.new(context: h[:context], state: h[:state]) }
      end
    end
  end
end
