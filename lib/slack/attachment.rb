module Slack
  # See https://api.slack.com/docs/attachments
  class Attachment
    include Virtus.model

    class Field
      include Virtus.model

      values do
        attribute :title, String
        attribute :value, String
        attribute :short, Boolean
      end
    end

    class Action
      include Virtus.model

      class Confirmation
        include Virtus.model

        values do
          attribute :title, String
          attribute :text, String
          attribute :ok_text, String
          attribute :dismiss_text, String
        end

        def as_json(options = {})
          super(options).reject { |_k, v| v.nil? }
        end
      end

      values do
        attribute :name, String
        attribute :text, String
        attribute :style, String
        attribute :type, String
        attribute :value, String
        attribute :confirm, Confirmation
      end

      def as_json(options = {})
        super(options).reject { |_k, v| v.nil? }
      end
    end

    values do
      attribute :mrkdwn_in, Array[String]
      attribute :text, String
      attribute :fallback, String
      attribute :callback_id, String
      attribute :color, String
      attribute :pretext, String
      attribute :author_name, String
      attribute :author_link, String
      attribute :author_icon, String
      attribute :title, String
      attribute :title_link, String
      attribute :fields, Array[Field]
      attribute :actions, Array[Action]
      attribute :image_url, String
      attribute :thumb_url, String
      attribute :footer, String
      attribute :footer_icon, String
      attribute :ts, Integer
    end

    def as_json(options = {})
      super(options).reject { |_k, v| v.nil? }
    end
  end
end
