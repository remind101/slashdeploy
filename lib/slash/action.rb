module Slash
  # Thing
  class Action
    attr_accessor :request

    def self.from_params(params = {})
      new Slash::ActionPayload.new(params)
    end

    def initialize(request = Slash::ActionPayload.new)
      @request = request
    end

  end
end
