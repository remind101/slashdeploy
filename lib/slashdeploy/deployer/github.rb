module SlashDeploy
  module Deployer
    # GitHub implements the Deployer interface backed by the github API.
    class GitHub
      attr_reader :client

      # Build builds a new instance with an octokit client backed by the access token.
      def self.call(user)
        new Octokit::Client.new(access_token: user.github_token)
      end

      def initialize(octokit_client)
        @client = octokit_client
      end

      # Creates a new deployment request on github.
      def create_deployment(req)
        options = {
          environment: req.environment,
          auto_merge: false,
          task: 'deploy'
        }
        options[:required_contexts] = [] if req.force

        deployment = client.create_deployment(req.repository, req.ref, options)
        deployment.id
      rescue Octokit::Conflict => e
        if e.errors[:field] == 'required_contexts'
          raise RedCommitError, commit_status_contexts(e.errors[:contexts])
        else
          raise
        end
      end

      private

      def commit_status_contexts(hash)
        hash.map { |h| CommitStatusContext.new(context: h[:context], state: h[:state]) }
      end
    end
  end
end
