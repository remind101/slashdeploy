require 'octokit'

module GitHub
  module Client
    # An implementation of the GitHub::Client interface backed by octokit.
    class Octokit
      def access?(user, repository)
        # Add a fake sha so we don't get any response data.
        user.octokit_client.deployments(repository, sha: '1')
        true
      rescue ::Octokit::NotFound
        false
      end
    end
  end
end
