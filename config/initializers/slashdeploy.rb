SlashDeploy.service.deployer = case Rails.configuration.x.deployer
                               when 'github'
                                 SlashDeploy::Deployer.github
                               else
                                 SlashDeploy::Deployer.fake
                               end

# Used to encode and sign the oauth state param for keeping track of a slack
# user id across github authentication.
SlashDeploy.state = SlashDeploy::State.new Rails.configuration.x.state_key
