SlashDeploy.service.deployer   = SlashDeploy::Deployer.new Rails.configuration.x.deployer
SlashDeploy.service.authorizer = SlashDeploy::Authorizer.new Rails.configuration.x.authorizer

# Used to encode and sign the oauth state param for keeping track of a slack
# user id across github authentication.
SlashDeploy.state = SlashDeploy::State.new Rails.configuration.x.state_key

