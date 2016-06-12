class UnauthorizedMessage < SlackMessage
  values do
    attribute :repository, Repository
  end

  def to_message
    Slack::Message.new text: text
  end
end
