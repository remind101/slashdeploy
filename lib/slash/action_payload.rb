module Slash
  # Action represents an incoming slack action
  class ActionPayload
    include Virtus.model

    class Action
      include Virtus.model

      values do
        attribute :name, String
        attribute :value, String
      end
    end

    class Team
      include Virtus.model

      values do
        attribute :id, String
        attribute :domain, String
      end
    end

    class Channel
      include Virtus.model

      values do
        attribute :id, String
        attribute :name, String
      end
    end

    class User
      include Virtus.model

      values do
        attribute :id, String
        attribute :name, String
      end
    end

    values do
      attribute :actions, Array[Action]
      attribute :callback_id, String
      attribute :team, Team
      attribute :channel, Channel
      attribute :user, User
      attribute :action_ts, String
      attribute :message_ts, String
      attribute :attachment_id, String
      attribute :token, String
      attribute :original_message, String
      attribute :response_url, String
    end
  end
end
