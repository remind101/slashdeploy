namespace :github do
  task :request_reauthenticate, [:user_id] => :environment do |t, args|
    users = User.all
    if user_id = args[:user_id]
      users = [User.find(user_id)]
    end

    users.each do |user|
      user.slack_accounts.each do |account|
        puts "Requesting user #{user.id} to re-authenticate"
        SlashDeploy.service.direct_message \
          account, \
          GitHubAuthenticateMessage, \
          url: Rails.application.routes.url_helpers.oauth_url(provider: 'github')
      end
    end
  end
end
