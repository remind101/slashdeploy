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
    def apps
      @apps ||= {}
    end

    def handle(event, app)
      apps[event.to_sym] = app
    end

    def call(env)
      app = apps[env[HEADER_GITHUB_EVENT].to_sym]
      return [404, {}, ['']] unless app
      app.call(env)
    end
  end
end
