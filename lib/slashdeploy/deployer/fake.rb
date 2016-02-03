module SlashDeploy
  module Deployer
    # Fake provides a fake implementation of the Deployer interface, which
    # simply records the requests in an in memory array.
    class Fake
      attr_reader :requests

      def self.call(_user)
        new
      end

      def initialize
        @requests = []
      end

      def create_deployment(req)
        requests << req
        1
      end

      def clear
        @requests = []
      end
    end
  end
end
