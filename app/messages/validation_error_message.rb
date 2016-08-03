class ValidationErrorMessage < SlackMessage
  values do
    attribute :record, Object
  end

  def to_message
    Slack::Message.new text: text
  end
end
