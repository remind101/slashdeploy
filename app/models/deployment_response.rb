# DeploymentResponse is returned when creating a new DeploymentRequest.
class DeploymentResponse
  include Virtus.value_object

  values do
    # The created deployment.
    attribute :deployment, Deployment
    # The last deployment to the given environment.
    attribute :last_deployment, Deployment
  end
end
