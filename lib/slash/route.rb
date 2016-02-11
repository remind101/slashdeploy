module Slash
  class Route
    attr_reader :matcher, :handler

    def initialize(matcher, handler)
      @matcher = matcher
      @handler = handler
    end

    def match(env)
      matcher.match(env)
    end

    def call(env)
      handler.call(env)
    end
  end
end
