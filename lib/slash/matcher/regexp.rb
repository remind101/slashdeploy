module Slash
  module Matcher
    # Regexp is a matcher that matches a regular expression, then returns the
    # named capture groups as params.
    class Regexp
      attr_reader :re

      def initialize(re)
        @re = re
      end

      def match(env)
        if env['action']
          if env['action'].request.callback_id != nil
            return {}
          end
        end
        return unless re =~ env['cmd'].request.text
        matches = ::Regexp.last_match
        Hash[matches.names.zip(matches.captures)]
      end
    end
  end
end
