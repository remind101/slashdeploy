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
        cmd = env['cmd']
        if ActiveSupport::SecurityUtils.secure_compare(cmd.request.token, token)
          handler.call(env)
        else
          fail UnverifiedError
        end
      end
    end
  end
end
