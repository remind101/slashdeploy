module Rack
  class StatsD
    METRIC_RACK_REQUEST = 'rack.request'.freeze

    attr_reader :app, :statsd

    def initialize(app, statsd = $statsd)
      @app = app
      @statsd = statsd
    end

    def call(env)
      statsd.time METRIC_RACK_REQUEST do
        app.call(env)
      end
    end
  end
end
