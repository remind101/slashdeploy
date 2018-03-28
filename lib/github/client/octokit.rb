require 'base64'
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
      rescue ::Octokit::UnprocessableEntity => e
        raise GitHub::BadRefError, req.ref if e.message =~ /No ref found for/
        raise
      end

      def last_deployment(user, repository, environment)
        deployments = user.octokit_client.deployments(repository, environment: environment)
        return if deployments.empty?
        deployment_from_github(repository, deployments.first)
      end

      def last_deployment_status(user, deployment_url)
        deployment_statuses = user.octokit_client.deployment_statuses(deployment_url)
        return if deployment_statuses.empty?
        deployment_status_from_github(deployments_statuses.first)
      end

      def access?(user, repository)
        # Add a fake sha so we don't get any response data.
        user.octokit_client.deployments(repository, sha: '1')
        true
      rescue ::Octokit::NotFound
        false
      end

      def contents(repository, path)
        client = repository.installation.octokit_client
        contents = client.contents(repository.name, path: path)
        Base64.decode64(contents.content)
      rescue ::Octokit::NotFound
        nil
      end

      private

      def deployment_from_github(repository, github_deployment)
        # https://developer.github.com/v3/repos/deployments/#response-1
        Deployment.new(
          id:          github_deployment.id,
          url:         github_deployment.url,
          ref:         github_deployment.ref,
          sha:         github_deployment.sha,
          environment: github_deployment.environment,
          repository:  repository
        )
      end

      def deployment_status_from_github(github_deployment_status)
        # https://developer.github.com/v3/repos/deployments/#response-3
        DeploymentStatus.new(
          id:             github_deployment_status.id,
          url:            github_deployment_status.url,
          description:    github_deployment_status.description,
          target_url:     github_deployment_status.target_url,
          deployment_url: github_deployment_status.deployment_url,
          repository_url: github_deployment_status.repository_url
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
