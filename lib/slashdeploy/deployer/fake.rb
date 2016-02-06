module SlashDeploy
  module Deployer
    # Fake provides a fake implementation of the Deployer interface, which
    # simply records the requests in an in memory array.
    class Fake
      attr_reader :requests

      def initialize
        clear
      end

      def create_deployment(user, req)
        fail RedCommitError, [CommitStatusContext.new(context: 'ci', state: 'failure')] if req.ref == 'failing' && !req.force
        requests << [user, req]
        1
      end

      def clear
        @requests = []
      end
    end
  end
end
