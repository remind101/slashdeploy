module SlashDeploy
  module Authorizer
    # An authorizer that uses the github api to check if the user has
    # permissions to access the repository.
    class GitHub
      def authorized?(user, repository)
        user.github_client.collaborator?(repository, user.github_login)
      end
    end
  end
end
