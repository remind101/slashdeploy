module SlashDeploy
  module Authorizer
    # An authorizer that uses the github api to check if the user has
    # permissions to access the repository.
    #
    # Ideally, we'd use the collaborators API (https://goo.gl/B48TiU).
    # Unfortunately, that requires obtaining the `repo` scope. Instead, this
    # implementation attempts to read the deployments on the repo. If that
    # succeeds, we know they have access to deploy.
    class GitHub
      def authorized?(user, repository)
        # Add a fake sha so we don't get any response data.
        user.github_client.deployments(repository, sha: '1')
        true
      rescue Octokit::NotFound
        false
      end
    end
  end
end
