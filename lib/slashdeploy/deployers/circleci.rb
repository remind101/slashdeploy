module SlashDeploy
  module Deployers
    class CircleCI
      attr_reader :connection

      def self.build
        connection = Faraday.new(url: 'https://circleci.com') do |faraday|
          faraday.request :json
          faraday.response :json
          faraday.adapter Faraday.default_adapter
        end
        new connection
      end

      def initialize(connection)
        @connection = connection
      end

      def deploy(repository, event)
        connection.post "/api/v1.1/project/github/#{repository}?circle-token=#{repository.circleci_api_token}", {
          revision: event['deployment']['sha'],
          build_parameters: {
            'GITHUB_DEPLOYMENT_ID': event['deployment']['id'],
            'GITHUB_DEPLOYMENT_ENVIRONMENT': event['deployment']['environment']
          }
        }
      end
    end
  end
end
