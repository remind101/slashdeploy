module SlashDeploy
  module Authorizer
    # A fake implementation of the authorizer that let's some people through.
    class Fake
      def authorized?(user, repository)
        fail('Expected a String repository') unless repository =~ SlashDeploy::GITHUB_REPO_REGEX
        return false if user.github_account.login == 'bob'
        true
      end
    end
  end
end
