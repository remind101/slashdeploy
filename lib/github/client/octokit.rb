require 'octokit'

module GitHub
  module Client
    # An implementation of the GitHub::Client interface backed by octokit.
    class Octokit
      def create_deployment(user, req)
        options = {
          environment: req.environment,
          auto_merge: false,
          task: 'deploy'
        }
        options[:required_contexts] = [] if req.force

        github_deployment = user.octokit_client.create_deployment(req.repository, req.ref, options)
        deployment_from_github(req.repository, github_deployment)
      rescue ::Octokit::Conflict => e
        error = required_contexts_error(e.errors)
        raise RedCommitError, commit_status_contexts(error[:contexts]) if error
        raise
      end

      def last_deployment(user, repository, environment)
        deployments = user.octokit_client.deployments(repository, environment: environment)
        return if deployments.empty?
        deployment_from_github repository, deployments.first
      end

      def access?(user, repository)
        # Add a fake sha so we don't get any response data.
        user.octokit_client.deployments(repository, sha: '1')
        true
      rescue ::Octokit::NotFound
        false
      end

      private

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
