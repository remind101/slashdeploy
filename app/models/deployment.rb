# Deployment represents a created DeploymentRequest.
class Deployment
  include Virtus.value_object

  values do
    # The external id of the deployment.
    attribute :id, Integer
    # The name of the repository the deployment was for.
    attribute :repository, String
    # The ref that was requested to be deployed.
    attribute :ref, String
    # The commit sha that the ref was resolved to (what actually got deployed).
    attribute :sha, String
    # The environment that was deployed to.
    attribute :environment, String
  end
end
