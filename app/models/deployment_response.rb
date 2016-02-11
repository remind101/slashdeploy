# DeploymentResponse is returned when creating a new DeploymentRequest.
class DeploymentResponse
  include Virtus.value_object

  values do
    # The created deployment.
    attribute :deployment, Deployment
    # The last deployment to the given environment.
    attribute :last_deployment, Deployment
  end

  def to_s
    deployment.to_s
  end

  # Returns a url with a diff between the old and new deployment.
  def diff_url
    return unless last_deployment
    return if deployment.sha == last_deployment.sha
    "https://github.com/#{deployment.repository}/compare/#{last_deployment.sha[0..5]}...#{deployment.sha[0..5]}"
  end
end
