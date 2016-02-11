module SlashDeploy
  module Deployer
    # Fake provides a fake implementation of the Deployer interface, which
    # simply records the requests in an in memory array.
    class Fake
      attr_reader :requests
      attr_reader :commits, :deployments

      def initialize
        reset
      end

      # Sets the HEAD commit for the given ref.
      # rubocop:disable Style/MethodName
      def HEAD(repo, ref, commit)
        commits[repo][ref] = commit
        commits[repo][commit] = commit
      end

      def create_deployment(user, req)
        fail RedCommitError, [CommitStatusContext.new(context: 'ci', state: 'failure')] if req.ref == 'failing' && !req.force
        requests << [user, req]
        id = @ids
        @ids += 1

        sha = commits[req.repository][req.ref]
        fail "No HEAD for #{req.ref}. Use `HEAD` to set it first." unless sha

        deployment = Deployment.new(
          id:          id,
          repository:  req.repository,
          ref:         req.ref,
          sha:         commits[req.repository][req.ref],
          environment: req.environment
        )
        last = deployments[req.repository][req.environment].last
        deployments[req.repository][req.environment] << deployment

        DeploymentResponse.new(
          deployment:      deployment,
          last_deployment: last
        )
      end

      def reset
        @ids = 1
        @commits = Hash.new do |commits, repo|
          commits[repo] = {}
        end
        @deployments = Hash.new do |deployments, repo|
          deployments[repo] = Hash.new do |repos, env|
            repos[env] = []
          end
        end
        @requests = []
      end
    end
  end
end
