require 'statsd'

# Create a stats interface
$statsd = Statsd.new('localhost', 8125)
$statsd.tags << "app:#{ENV['HEROKU_APP_NAME']}"
$statsd.tags << "dyno:#{ENV['DYNO']}"
$statsd.tags << "release:#{ENV['HEROKU_RELEASE_VERSION']}"
