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
        case env['type']
        when 'cmd'
          request_token = env['cmd'].token
        when 'action'
          request_token = env['action'].token
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
