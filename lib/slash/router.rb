module Slash
  # Router is a slash handler router.
  class Router
    attr_reader :routes

    # This is a Slash::Handler that will be called if there is no matching
    # route.
    attr_accessor :not_found

    def initialize
      @routes = []
    end

    # Match adds a new handler that will be called when the slash command
    # matches the given matcher.
    def match(matcher, handler)
      routes << Route.new(matcher, handler)
    end

    # Returns the route that matches the request. Returns nil if there is no
    # matching route.
    def route(env)
      routes.each do |route|
        return route if route.match(env)
      end

      nil
    end

    # Finds the first handler that matches the slash command, and calls it with
    # the parameters returned from the matcher.
    def call(env)
      route = self.route(env)
      if route
        env['params'] = route.match(env) || {}
        route.call(env)
      else
        env['params'] = {}
        not_found.call(env)
      end
    end
  end
end
