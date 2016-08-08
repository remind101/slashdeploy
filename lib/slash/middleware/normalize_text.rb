module Slash
  module Middleware
    class NormalizeText
      attr_reader :handler

      def initialize(handler)
        @handler = handler
      end

      def call(env)
        cmd = env['cmd']
        cmd.payload.text = cmd.payload.text.squeeze(' ').strip
        @handler.call(env)
      end
    end
  end
end
