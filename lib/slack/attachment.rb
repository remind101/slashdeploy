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

    values do
      attribute :mrkdwn_in, Array[String]
      attribute :text, String
      attribute :fallback, String
      attribute :color, String
      attribute :pretext, String
      attribute :author_name, String
      attribute :author_link, String
      attribute :author_icon, String
      attribute :title, String
      attribute :title_link, String
      attribute :fields, Array[Field]
      attribute :image_url, String
      attribute :thumb_url, String
      attribute :footer, String
      attribute :footer_icon, String
      attribute :ts, Integer
    end
  end
end
