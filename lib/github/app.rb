module GitHub
  class App
    def self.build(app_id, private_pem)
      new app_id, OpenSSL::PKey::RSA.new(private_pem)
    end

    def initialize(app_id, private_key)
      @app_id = app_id
      @private_key = private_key
    end

    def app_token
      # Generate the JWT
      payload = {
        # issued at time
        iat: Time.now.to_i,
        # JWT expiration time (10 minute maximum)
        exp: 1.minutes.from_now.to_i,
        # Integration's GitHub identifier
        iss: @app_id
      }

      JWT.encode(payload, @private_key, "RS256")
    end

    def installation_token(installation)
      client = Octokit::Client.new(bearer: app_token)
      resp = client.create_installation_access_token(installation)
      resp['token']
    end
  end
end
