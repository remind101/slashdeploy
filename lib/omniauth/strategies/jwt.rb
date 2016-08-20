require 'omniauth'
require 'jwt'

module OmniAuth
  module Strategies
    class JWT
      include OmniAuth::Strategy

      args [:secret]

      option :secret, nil
      option :algorithm, 'HS256'
      option :name, 'jwt'

      uid { decoded['id'] }

      extra do
        { raw_info: decoded }
      end

      def callback_phase
        super
      rescue ::JWT::DecodeError => e
        fail!(:invalid_credentials, e)
      end

      private

      def decoded
        @decoded ||= ::JWT.decode(request.params['jwt'], options.secret, options.algorithm).first
      end
    end

    # So it gets registered properly with omniauth.
    class Jwt < JWT; end
  end
end
