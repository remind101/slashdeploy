module GitHub
  module Client
    class Fake
      def access?(user, repository)
        fail('Expected a String repository') unless repository =~ SlashDeploy::GITHUB_REPO_REGEX
        return false if user.github_account.login == 'bob'
        true
      end
    end
  end
end
