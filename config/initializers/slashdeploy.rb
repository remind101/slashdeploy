SlashDeploy.service.github = GitHub::Client.new(Rails.configuration.x.github_client)
SlashDeploy.service.slack = Slack::Client.new(Rails.configuration.x.slack_client)
