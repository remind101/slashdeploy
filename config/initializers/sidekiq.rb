# When the BACKUP_S3_BUCKET env var is present,
# schedule cronjobs for workers which create backups.
#if Rails.config.x.backup_s3_bucket && Sidekiq.server?
if Rails.application.config.x.backup_s3_bucket && Sidekiq.server?
  # run the ETL to send the Slack+Github user map to S3.
  params = {
    "backup_user_mapping" => {
      "cron" => "35 23 * * *",
      "class" => "ExportUserMapWorker"
    }
  }
  Sidekiq::Cron::Job.load_from_hash params
end
