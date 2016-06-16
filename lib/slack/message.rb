module Slack
  # Message is a ruby representation of a Slack message.
  #
  # See https://api.slack.com/docs/formatting/builder
  class Message
    include Virtus.model

    values do
      attribute :text, String
      attribute :attachments, Array[Attachment]
    end
  end
end
