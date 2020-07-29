require 'json'
require 'aws-sdk'

namespace :user_mapping do
  task :configure => :environment do |t, args|
    # Configure the AWS SDK so that we can use minio in development.
    Aws.config.update(
      endpoint: Rails.configuration.x.backup_s3_endpoint,
      access_key_id: Rails.configuration.x.backup_s3_access_key_id,
      secret_access_key: Rails.configuration.x.backup_s3_secret_access_key,
      region: Rails.configuration.x.backup_aws_region,
      # This is required to be compatible with minio for local development. This
      # option disables using subdomains for access S3 buckets
      # (slashdeploy.amazonaws.com vs amazonaws.com/slashdeploy etc.)
      force_path_style: true,
    )

    # If a role is set, we assume that we need to assume it.
    unless Rails.configuration.x.backup_s3_role_arn.nil?
      res = Aws::STS::Client.new.assume_role({
        role_arn: Rails.configuration.x.backup_s3_role_arn,
        role_session_name: "slashdeploy-user_mapping-create-bucket"
      })

      # Reconfigure the client with the assumed role.
      Aws.config.update(
        access_key_id: res.credentials.access_key_id,
        secret_access_key: res.credentials.secret_access_key
      )
    end
  end

  task :create_bucket => :configure do |t, args|
    # Create the bucket we're using; mostly for development/testing.
    Aws::S3::Client.new.create_bucket({
      bucket: Rails.configuration.x.backup_s3_bucket_name
    })
  end

  task :push => :configure do |t, args|
    # https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/S3/Client.html
    s3_client = Aws::S3::Client.new

    # https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/S3/Resource.html
    bucket = Aws::S3::Resource.new(client: s3_client).bucket(Rails.configuration.x.backup_s3_bucket_name)

    # Go through each Slack team with have in the DB.
    SlackTeam.all.each do |team|
      # Get all the users for the team. We only care about the Slack <-> GitHub
      # mapping.
      query = User.select(
        :id,
        "slack_accounts.user_name as slack_nickname",
        "github_accounts.login as github_login",
      ).joins(
        :slack_accounts,
        :github_accounts
      ).distinct

      # Add all the users to the team data and dump it to JSON.
      json = JSON.dump({
        slack_domain: team.domain,
        github_organization: team.github_organization,
        users: query.as_json
      })

      # Upload the file to S3.
      bucket.put_object({
        key: "user_mappings/#{team.domain}-#{team.github_organization}.json",
        body: json,
      })
    end
  end

  task :list => :configure do |t, args|
    # Print out a list of all the objects in the bucket. (Up to the max results
    # AWS will return).
    puts Aws::S3::Client.new.list_objects({
      bucket: Rails.configuration.x.backup_s3_bucket_name
    })
  end
end
