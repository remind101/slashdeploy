module Slash
  module Middleware
    # Provides a slash handler middleware that verifies the request was from
    # Slack.
    class Verify
      attr_reader :handler
      attr_reader :token

      def initialize(handler, token)
        @handler = handler
        @token = token
      end

      # Wraps handler in middleware that verifies the token.
      def call(env)
        # cmd = env['cmd']
        request_token = nil
        if env['cmd'].request.token
          request_token = env['cmd'].request.token
        else
          request_token = env['action'].request.token
        end
        if ActiveSupport::SecurityUtils.secure_compare(request_token, token)
          handler.call(env)
        else
          fail UnverifiedError
        end
      end
    end
  end
end
