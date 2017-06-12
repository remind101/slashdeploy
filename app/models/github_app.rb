class GitHubApp
  def initialize(installation)
    @installation = installation
  end

  def identifier
    "SlashDeploy"
  end

  def slack_account_for_github_organization(org)
  end

  def github_token
    SlashDeploy.github_app.installation_token(@installation)
  end

  def octokit_client
    Octokit::Client.new(bearer: github_token)
  end

  def deployer
    nil
  end
end
