SlashDeploy.service.github_client = GitHub::Client.new(Rails.configuration.x.github_client)
SlashDeploy.service.deployer = SlashDeploy::Deployer.new Rails.configuration.x.deployer

# Used to encode and sign the oauth state param for keeping track of a slack
# user id across github authentication.
SlashDeploy.state = SlashDeploy::State.new Rails.configuration.x.state_key

