web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -c 2 -q auto_deployment_watchdog -q github_deployment_watchdog -q lock_nag
