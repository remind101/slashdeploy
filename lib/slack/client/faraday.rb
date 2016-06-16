module Slack
  module Client
    class Faraday
      attr_reader :connection

      def self.build(url = 'https://slack.com')
        conn = ::Faraday.new(url: url) do |faraday|
          faraday.request :url_encoded
          faraday.adapter ::Faraday.default_adapter
        end
        new(conn)
      end

      def initialize(connection)
        @connection = connection
      end

      def direct_message(slack_account, message)
        params = message.to_h.merge(
          token: slack_account.bot_access_token,
          channel: slack_account.id
        )

        connection.post '/api/chat.postMessage', params
      end
    end
  end
end
