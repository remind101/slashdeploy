module Slash
  # Rack provides a Rack compatible application to serve a slash handler.
  class Rack
    attr_reader :handler

    def initialize(handler)
      @handler = handler
    end

    # Call parses the slack slash command and calls the handler.
    def call(env)
      req = Slash::Request.new ::Rack::Request.new(env).POST
      cmd = Slash::Command.new req
      response = handler.call('cmd' => cmd)
      if response
        [200, { 'Content-Type' => 'application/json' }, [response.to_json]]
      else
        [200, {}, ['']]
      end
    end
  end
end
