# Instances of this class represent state in Github's API.
# Deployment represents a created DeploymentRequest.
class Deployment
  include Virtus.value_object

  # http://rubular.com/r/ahTMm18LGA
  GITHUB_DEPLOYMENT_URL_REGEX_TO_MATCH_ORG_AND_REPO = %r{https:\/\/api.github.com\/repos\/([\w\-]+)\/([\w\-\.]+)}

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

  # memoize the result to limit repeated computations.
  def org_and_repo
    @org_and_repo ||= GITHUB_DEPLOYMENT_URL_REGEX_TO_MATCH_ORG_AND_REPO.match(url)
  end

  # return the Github Org for deployment.
  def organization
    # example url: "https://api.github.com/repos/octocat/example/deployments/1"
    # would result in the following organization: "octocat"
    org_and_repo[1]
  end

  # TODO: could we use this instead of passing the repository as an argument?
  # # return the Github Repo for deployment.
  # def repository
  #   # given the url: "https://api.github.com/repos/octocat/example/deployments/1"
  #   # would result in the following repository: "example"
  #   org_and_repo[2]
  # end
end
