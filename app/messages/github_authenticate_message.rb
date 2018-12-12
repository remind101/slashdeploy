class GitHubAuthenticateMessage < SlackMessage
  values do
    attribute :url, String
  end

  def to_message
    Slack::Message.new text: "Please reconnect your GitHub account by visiting #{url}"
  end
end
