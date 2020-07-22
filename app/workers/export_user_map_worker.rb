class ExportUserMapWorker
  include Sidekiq::Worker

  def perform()

    # https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/S3/Client.html
    s3_client = Aws::S3::Client.new(
      access_key_id: Rails.configuration.x.backup_s3_access_key,
      secret_access_key: Rails.configuration.x.backup_s3_secret_key,
    )
    # https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/S3/Resource.html
    s3 = Aws::S3::Resource.new(client: s3_client)

    slack_teams = SlackTeam.find_each do |slack_team|
      puts slack_team.github_organization
      puts slack_team.id
      puts slack_team.domain
      slack_team.slack_accounts.each do |slack_account|
        puts slack_account.id
        puts slack_account.user_name
        puts slack_account.user.github_account.id
        puts slack_account.user.github_account.user_name
      end
    end

  end
end
