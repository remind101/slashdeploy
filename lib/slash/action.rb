module Slash
  class Action
    attr_accessor :payload

    def self.from_params(params = {})
      new Slash::ActionPayload.new(params)
    end

    def initialize(payload = Slash::ActionPayload.new)
      @payload = payload
    end

    def empty?
      payload.callback_id == nil
    end
  end
end
