# Instances of this class represent state in Github's API.
# Querying a Github Deployment's list of statuses, returns a JSON payload.
# This class represents a single status item and holds the fields we need.
# References:
# * https://developer.github.com/v3/repos/deployments/#list-deployment-statuses
# * https://octokit.github.io/octokit.rb/Octokit/Client/Deployments.html#deployment_statuses-instance_method
class DeploymentStatus
  include Virtus.value_object

  values do
    # The external id of the deployment_status item.
    attribute :id, Integer
    # The external url of the deployment_status item.
    attribute :url, String
    # The state of the deployment_status item.
    attribute :state, String
    # The description of the deployment_status item.
    attribute :description, String
    # The 3rd party url of the deployment_status item.
    attribute :target_url, String
    # The deployment url of the deployment_status item.
    attribute :deployment_url, String
    # The repository url of the deployment_status item.
    attribute :repository_url, String
  end
end
