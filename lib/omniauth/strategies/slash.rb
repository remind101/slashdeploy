require 'omniauth'

module OmniAuth
  module Strategies
    class Slash
      include OmniAuth::Strategy

      def request_phase
        redirect "#{callback_path}?account=#{request.params['account']}"
      end

      uid do
        decoded['id']
      end

      info do
        { nickname:    decoded['user_name'],
          team_id:     decoded['team_id'],
          user_id:     decoded['user_id'],
          team_domain: decoded['team_domain'] }
      end

      def decoded
        @decoded ||= ::SlashDeploy.state.decode(request.params['account'])
      end
    end
  end
end
