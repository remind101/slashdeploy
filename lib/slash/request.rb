module Slash
  # Request represents an incoming slash command request.
  class Request
    include Virtus.value_object

    values do
      attribute :token, String
      attribute :team_id, String
      attribute :team_domain, String
      attribute :channel_id, String
      attribute :channel_name, String
      attribute :user_id, String
      attribute :user_name, String
      attribute :command, String
      attribute :text, String
      attribute :response_url, String
    end
  end
end
