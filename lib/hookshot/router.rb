require 'rack'

module Hookshot
  # Router is a Rack application that demuxes GitHub webhooks to other Rack
  # applications.
  #
  # Example
  #
  #   router = Hookshot::Router.new
  #   router.handle :push, PushHandler.new
  #   router.handle :deployment, DeploymentHandler.new
  class Router
    # Rack app that gets called when a handler is not found.
    attr_accessor :not_found

    def apps
      @apps ||= {}
    end

    def handle(event, app)
      apps[event.to_sym] = app
    end

    def call(env)
      app = apps[env[HEADER_GITHUB_EVENT].to_sym]
      return not_found.call(env) unless app
      app.call(env)
    end

    def not_found
      @not_found ||= -> (_env) { [204, {}, ['']] }
    end
  end
end
