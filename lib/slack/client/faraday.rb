module Slack
  module Client
    class Faraday
      attr_reader :connection

      def self.build_faraday_connection(url: 'https://slack.com', adapter: ::Faraday.default_adapter)
        ::Faraday.new(url: url) do |faraday|
          faraday.request :url_encoded
          faraday.use CheckError
          faraday.response :json
          faraday.adapter adapter
        end
      end

      def self.build(*args)
        new(build_faraday_connection(*args))
      end

      def initialize(connection)
        @connection = connection
      end

      def direct_message(slack_account, message)
        params = message.to_h

        params.delete(:attachments) unless params[:attachments].present?
        # From https://api.slack.com/methods/chat.postMessage
        #
        # > The optional attachments argument should contain a JSON-encoded array of attachments.
        params[:attachments] = params[:attachments].to_json if params[:attachments]

        connection.post '/api/chat.postMessage', params.merge(
          token: slack_account.bot_access_token,
          channel: slack_account.id
        )
      end

      # Middleware that checks the response from the API, and raises an error
      # if the `ok` attribute is false.
      #
      # See https://api.slack.com/web
      class CheckError
        attr_reader :app

        def initialize(app)
          @app = app
        end

        def call(request_env)
          @app.call(request_env).on_complete do |response_env|
            body = response_env[:body]
            fail ::Slack::Client::Error, body['error'] unless body['ok']
          end
        end
      end
    end
  end
end
