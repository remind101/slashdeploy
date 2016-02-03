module Slash
  # Response represents the object we send to slack when we want to respond to
  # a users slash command request.
  class Response
    include Virtus.value_object

    values do
      attribute :in_channel, Boolean
      attribute :text, String
    end

    def to_json
      h = { 'text' => text }
      h['response_type'] = 'in_channel' if in_channel
      h.to_json
    end
  end
end
