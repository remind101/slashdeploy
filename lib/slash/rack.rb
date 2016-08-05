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
      action_payload = ::Rack::Request.new(env).POST['payload']
      action = nil
      if action_payload
        action = Slash::Action.from_params JSON.parse(action_payload)
      end
      begin
        response = handler.call('cmd' => cmd, 'action' => action)
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
