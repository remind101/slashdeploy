class RedCommitMessage < SlackMessage
  values do
    attribute :failing_contexts, Array[CommitStatusContext]
    attribute :request, Slash::Request
  end

  def to_message
    Slack::Message.new text: text
  end
end
