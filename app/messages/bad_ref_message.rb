class BadRefMessage < SlackMessage
  values do
    attribute :repository, Repository
    attribute :ref, String
  end

  def to_message
    Slack::Message.new text: text
  end
end
