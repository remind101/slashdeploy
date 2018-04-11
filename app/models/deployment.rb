# Instances of this class represent state in Github's API.
# Deployment represents a created DeploymentRequest.
class Deployment
  include Virtus.value_object

  values do
    # The external id of the deployment.
    attribute :id, Integer
    # The external url of the deployment, needed to lookup statuses.
    attribute :url, String
    # The ref that was requested to be deployed.
    attribute :ref, String
    # The commit sha that the ref was resolved to (what actually got deployed).
    attribute :sha, String
    # The environment that was deployed to.
    attribute :environment, String
    # The name of the repository the deployment was for.
    attribute :repository, String
  end

  # return the Github Org for deployment.
  def organization
    matches = SlashDeploy::GITHUB_REPO_REGEX.match(repository)
    matches[1]
  end
end
