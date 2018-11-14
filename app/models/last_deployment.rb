# Represents the latest deployment for a repository and an environment
class LastDeployment
  include Virtus.value_object
   values do
    # The last deployment.
    attribute :last_deployment, Deployment
    # The last deployment status
    attribute :last_deployment_status, DeploymentStatus
  end
end