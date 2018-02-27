require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'logger'
require 'active_support/logger'

module Perty
  # BetterTaggedLogging is based on ActiveSupport::TaggedLogging to make log
  # messages pretty and useful.
  #
  # See also https://goo.gl/907QWS
  module Logger
    module Formatter # :nodoc:
      # This method is invoked when a log event occurs.
      def call(severity, timestamp, progname, msg)
        parts = []
        modules.each do |mod|
          parts << ["[#{mod}]"]
        end
        parts << ["request_id=#{context[:request_id]}"] if context[:request_id]
        parts << msg
        super(severity, timestamp, progname, parts.join(' '))
      end

      def with_module(mod)
        modules << mod
        yield self
      ensure
        modules.pop
      end

      def with_request_id(request_id)
        context[:request_id] = request_id
        yield self
      ensure
        context[:request_id] = nil
      end

      def modules
        context[:modules] ||= []
      end

      def context
        Thread.current[:perty] ||= {}
      end
    end

    def self.new(logger)
      # Ensure we set a default formatter so we aren't extending nil!
      logger.formatter ||= ActiveSupport::Logger::SimpleFormatter.new
      logger.formatter.extend Formatter
      logger.extend(self)
    end

    delegate :with_request_id, :with_module, to: :formatter
  end
end
