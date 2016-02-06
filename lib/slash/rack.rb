require 'rack'

module Slash
  # Rack provides a Rack compatible application to serve a slash handler.
  class Rack
    attr_reader :handler

    def initialize(handler)
      @handler = handler
    end

    # Call parses the slack slash command and calls the handler.
    def call(env)
      cmd = Slash::Command.from_params ::Rack::Request.new(env).POST
      begin
        response = handler.call('cmd' => cmd)
        if response
          [200, { 'Content-Type' => 'application/json' }, [response.to_json]]
        else
          [200, {}, ['']]
        end
      rescue UnverifiedError
        [403, {}, ['']]
      end
    end
  end
end
