module Slash
  module Middleware
    # Logs the command.
    class Logging
      def initialize(handler, logger = Rails.logger)
        @handler = handler
        @logger = logger
      end

      def call(env)
        request = env['cmd'].request
        @logger.with_module('slack command') do
          @logger.info "command=#{request.command} text=#{request.text} user_name=#{request.user_name} user_id=#{request.user_id} team_domain=#{request.team_domain} team_id=#{request.team_id} channel_id=#{request.channel_id} channel_name=#{request.channel_name}"
          @handler.call(env)
        end
      end
    end
  end
end
