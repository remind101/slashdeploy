module Slash
  module Middleware
    class NormalizeText
      attr_reader :handler

      def initialize(handler)
        @handler = handler
      end

      def call(env)
        cmd = env['cmd']
        if cmd.payload.text
          cmd.payload.text = cmd.payload.text.squeeze(' ').strip
        end
        @handler.call(env)
      end
    end
  end
end
