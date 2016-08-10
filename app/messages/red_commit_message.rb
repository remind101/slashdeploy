class RedCommitMessage < SlackMessage
  values do
    attribute :failing_contexts, Array[CommitStatusContext]
    attribute :command_payload, Slash::CommandPayload
  end

  def to_message
    Slack::Message.new text: text
  end
end
