require 'rails'

module Perty
  # Rack middleware the logs the request with a perty logger.
  class Rack < ::Rails::Rack::Logger
    attr_reader :logger

    def initialize(app, logger = Rails.logger)
      @app = app
      @logger = logger
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      @logger.with_request_id(env['action_dispatch.request_id']) do
        call_app(request, env)
      end
    end
  end
end
