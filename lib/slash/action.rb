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
      payload.attributes.all? { |_k, v| v.nil? }
    end

    def value
      payload.actions.first.value
    end

    def user_id
      payload.user ? payload.user.id : nil
    end

    def user_name
      payload.user ? payload.user.name : nil
    end

    def team_id
      payload.team ? payload.team.id : nil
    end

    def team_domain
      payload.team ? payload.team.domain : nil
    end

    def channel_id
      payload.channel ? payload.channel.id : nil
    end

    def channel_name
      payload.channel ? payload.channel.name : nil
    end

    delegate :token, to: :payload
  end
end
