if url = ENV['URL']
  uri = URI.parse(url)

  Rails.application.routes.default_url_options[:host] = uri.host
  Rails.application.routes.default_url_options[:protocol] = uri.scheme
  OmniAuth.config.full_host = uri.to_s
else
  Rails.application.routes.default_url_options[:host] = 'localhost:5000'
end
