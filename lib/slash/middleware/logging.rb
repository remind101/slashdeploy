module Slash
  module Middleware
    # Logs the command.
    class Logging
      def initialize(handler, logger = Rails.logger)
        @handler = handler
        @logger = logger
      end

      def call(env)
        case env['type']
        when 'cmd'
          payload = env['cmd'].payload
          @logger.with_module('slack command') do
            @logger.info "command=#{payload.command} text=#{payload.text} user_name=#{payload.user_name} user_id=#{payload.user_id} team_domain=#{payload.team_domain} team_id=#{payload.team_id} channel_id=#{payload.channel_id} channel_name=#{payload.channel_name}"
            @handler.call(env)
          end
        when 'action'
          payload = env['action'].payload
          @logger.with_module('slack action') do
            @logger.info "callback_id=#{payload.callback_id} action_ts=#{payload.action_ts} message_ts=#{payload.message_ts} attachment_id=#{payload.attachment_id} response_url=#{payload.response_url} user_name=#{payload.user.name} user_id=#{payload.user.id} team_domain=#{payload.team.domain} team_id=#{payload.team.id} channel_id=#{payload.channel.id} channel_name=#{payload.channel.name}"
            @handler.call(env)
          end
        end
      end
    end
  end
end
