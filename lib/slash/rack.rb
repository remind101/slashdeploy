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
      req = ::Rack::Request.new(env)
      params = {'rack.env' => env}

      payload = req.POST['payload']
      if payload
        params['type'] = 'action'
        params['action'] = Slash::Action.from_params JSON.parse(payload)
      else
        params['type'] = 'cmd'
        params['cmd'] = Slash::Command.from_params req.POST
      end

      begin
        response = handler.call(params)
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
