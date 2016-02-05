module SlashDeploy
  module Deployer
    # Fake provides a fake implementation of the Deployer interface, which
    # simply records the requests in an in memory array.
    class Fake
      attr_reader :requests

      def initialize
        clear
      end

      def call(user)
        Deployer.new user, requests
      end

      def clear
        @requests = []
      end

      # Deployer implements the deployer interface which records the deployment
      # request and the user that made it.
      class Deployer
        attr_reader :user
        attr_reader :requests

        def initialize(user, requests)
          @user = user
          @requests = requests
        end

        def create_deployment(req)
          fail RedCommitError, [CommitStatusContext.new(context: 'ci', state: 'failure')] if req.ref == 'failing' && !req.force
          requests << [user, req]
          1
        end
      end
    end
  end
end
