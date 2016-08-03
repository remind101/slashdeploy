class ValidationErrorMessage < SlackMessage
  values do
    attribute :record, Object
  end

  def to_message
    fields = record.errors.map do |attribute, error|
      Slack::Attachment::Field.new title: "#{record.class.name.downcase} #{attribute}", value: error
    end
    Slack::Message.new text: text, attachments: [
      Slack::Attachment.new(fields: fields, color: '#f00')
    ]
  end
end
