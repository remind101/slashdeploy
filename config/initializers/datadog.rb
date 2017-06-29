Rails.configuration.datadog_trace = {
  auto_instrument: true,
  auto_instrument_redis: true,
  default_service: ENV['HEROKU_APP_NAME']
}
