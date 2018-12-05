class GitHubAuthenticateMessage < SlackMessage
  values do
    attribute :url, String
  end

  def to_message
    Slack::Message.new text: "Please authenticate with GitHub: #{url}"
  end
end
