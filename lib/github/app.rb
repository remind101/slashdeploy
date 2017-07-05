require 'octokit'
require 'jwt'
require 'openssl'

module GitHub
  # Represents a "GitHub App", and provides methods for obtaining "app" tokens,
  # as well as "installation" tokens.
  #
  # See https://developer.github.com/apps/
  class App
    def self.build(app_id, private_pem)
      new app_id, OpenSSL::PKey::RSA.new(private_pem)
    end

    def initialize(app_id, private_key, time: Time)
      @app_id = app_id
      @private_key = private_key
      @time = time
      @installation_tokens = TokenCache.new(time: time)
    end

    # Returns an "app" token that can be used to authenticate as the GitHub App.
    #
    # Authenticating as a GitHub App lets you retrieve high-level management
    # information about your GitHub App and request access tokens for an
    # installation.
    #
    # See https://goo.gl/7WUMPJ
    def app_token(expiration: 1.minute)
      now = @time.now
      exp = now + expiration

      # Generate the JWT
      payload = {
        # issued at time
        iat: now.to_i,
        # JWT expiration time (10 minute maximum)
        exp: exp.to_i,
        # Integration's GitHub identifier
        iss: @app_id
      }

      JWT.encode(payload, @private_key, 'RS256')
    end

    # Returns an "installation" token, using the in memory cache if available.
    def installation_token(installation_id)
      @installation_tokens[installation_id] ||= installation_token!(installation_id)
    end

    # Fetches an "installation" token that can be used to authenticate as an
    # installation of the GitHub App.
    #
    # Authenticating as an installation lets you perform actions in the API for
    # that installation. Before authenticating as an installation, you must
    # create an access token. These installation access tokens are used by
    # GitHub Apps to authenticate.
    #
    # See https://goo.gl/KjHwmX
    def installation_token!(installation_id)
      client = Octokit::Client.new(bearer_token: app_token)
      resp = client.create_installation_access_token(installation_id, accept: 'application/vnd.github.machine-man-preview+json')
      InstallationToken.new(resp['token'], resp['expires_at'])
    end

    InstallationToken = Struct.new(:token, :expires_at)

    # TokenCache is used internally to cache installation tokens until they
    # expire.
    class TokenCache
      def initialize(time: Time, jitter: 1.minute)
        @store = {}
        @time = time
        @jitter = jitter
      end

      def [](installation_id)
        token = @store[installation_id]
        return unless token
        return if (@time.now + @jitter) > token.expires_at # Expired
        token
      end

      def []=(installation_id, token)
        @store[installation_id] = token
      end
    end
  end
end
