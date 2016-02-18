SlashDeploy.service.github = GitHub::Client.new(Rails.configuration.x.github_client)

# Used to encode and sign the oauth state param for keeping track of a slack
# user id across github authentication.
SlashDeploy.state = SlashDeploy::State.new Rails.configuration.x.state_key

