module SlashDeploy
  # State can be used to encode and sign some arbitrary data, then decode and
  # verify later.
  class State
    # Expire tokens after 1 minute.
    EXPIRATION = 1.minute

    attr_reader :secret

    def initialize(secret)
      @secret = secret
    end

    # JWT encodes the user id.
    def encode(data)
      JWT.encode data.merge(exp: Time.now.to_i + EXPIRATION), secret
    end

    # JWT decodes the user id, verifies it and returns the id.
    def decode(state)
      decoded = JWT.decode state, secret, true, algorithm: 'HS256'
      decoded.first
    end
  end
end
