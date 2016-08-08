module Slash
  # Command represents an incoming slash command.
  class Command
    attr_accessor :payload

    def self.from_params(params = {})
      new Slash::CommandPayload.new(params)
    end

    def initialize(payload = Slash::CommandPayload.new)
      @payload = payload
    end

    def empty?
      # TODO: Check if Virtus has something that checks for all nil
      payload.command.nil?
    end

    def exists?
      !empty?
    end

    def ===(other)
      payload == other.payload
    end

    def respond(response)
      uri = URI.parse(payload.response_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      http.post(uri.path, response.to_json, 'Content-Type' => 'application/json')
      nil
    end

    # delegate :token, to: :payload
    # delegate :user_id, user_name, team_id, team_domain auth.rb
  end
end
