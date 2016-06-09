module Slack
  module Client
    class Faraday
      attr_reader :connection

      def self.build(url = 'https://slack.com')
        conn = Faraday.new(url: url) do |faraday|
          faraday.request :url_encoded
          faraday.adapter Faraday.default_adapter
        end
        new(conn)
      end

      def initialize(connection)
        @connection = connection
      end

      def direct_message(slack_account, message)
        connection.post \
          '/api/chat.postMessage',
          token: slack_account.bot_access_token,
          channel: slack_account.id,
          text: message
      end
    end
  end
end
