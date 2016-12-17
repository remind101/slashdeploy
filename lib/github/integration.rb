require 'jwt'
require 'faraday'
require 'faraday_middleware'

module GitHub
  # Represents a GitHub Integration, and provides methods for generating
  # installation access tokens.
  #
  # See https://developer.github.com/early-access/integrations/
  class Integration
    class AccessToken
      include Virtus.value_object

      values do
        attribute :token, String
        attribute :expires_at, DateTime
      end
    end

    ACCEPT_HEADER = 'application/vnd.github.machine-man-preview+json'.freeze

    # Amount of time until an integration token expires.
    INTEGRATION_TOKEN_EXPIRATION = 1.minute

    attr_reader :private_key
    attr_reader :id

    def initialize(connection, private_key, id)
      @connection = connection
      @private_key = private_key
      @id = id
      @user_tokens = {}
    end

    def installation_token(installation_id, on_behalf_of: nil)
      if on_behalf_of
        @user_tokens[on_behalf_of] = new_installation_token(installation_id, on_behalf_of: on_behalf_of) if @user_tokens[on_behalf_of].nil? || @user_tokens[on_behalf_of].expired?
        @user_tokens[on_behalf_of]
      else
        @installation_token = new_installation_token(installation_id) if @installation_token.nil? || @installation_token.expired?
        @installation_token
      end
    end

    private

    def new_installation_token(installation_id, on_behalf_of: nil)
      resp = @connection.post "/installations/#{installation_id}/access_tokens" do |req|
        req.headers['Authorization'] = "Bearer #{integration_token}"
        req.headers['Accept'] = ACCEPT_HEADER
        req.body = { user_id: on_behalf_of } if on_behalf_of
      end
      AccessToken.new(token: resp.body['token'], expires_at: resp.body['expires_at'])
    end

    # Generates a JWT signed integration token.
    #
    # See https://developer.github.com/early-access/integrations/authentication/
    def integration_token
      payload = {
        iat: Time.now.to_i,
        exp: INTEGRATION_TOKEN_EXPIRATION.from_now.to_i,
        iss: id
      }
      JWT.encode(payload, private_key, 'RS256')
    end
  end
end
