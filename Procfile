web:
  command: bundle exec puma -C config/puma.rb

worker:
  command: bundle exec sidekiq -c 2 -q deployment_watchdog
