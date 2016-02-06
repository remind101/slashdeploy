module Slash
  # Command represents an incoming slash command.
  class Command
    attr_accessor :request

    def self.from_params(params = {})
      new Slash::Request.new(params)
    end

    def initialize(request = Slash::Request.new)
      @request = request
    end

    def ===(other)
      request == other.request
    end

    def respond(response)
      uri = URI.parse(request.response_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      http.post(uri.path, response.to_json, 'Content-Type' => 'application/json')
      nil
    end
  end
end
