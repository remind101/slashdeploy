module SlashDeploy
  module Authorizer
    # A fake implementation of the authorizer that let's some people through.
    class Fake
      def authorized?(user, _repository)
        return false if user.github_account.login == 'bob'
        true
      end
    end
  end
end
