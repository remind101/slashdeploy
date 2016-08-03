source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.5.1'
gem 'uglifier', '>= 1.3.0'
gem 'jquery-rails'
gem 'turbolinks'
gem 'octokit'
gem 'virtus'
gem 'pg'
gem 'postgres_ext'
gem 'oj'
gem 'puma'
gem 'sass'

gem 'faraday'
gem 'faraday_middleware'

# Visibility
gem 'rollbar', '~> 2.8.0'
gem 'lograge'
gem 'dogstatsd-ruby'

# Auth
gem 'jwt'
gem 'warden'
gem 'oauth2'
gem 'omniauth'
gem 'omniauth-github'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'rspec-rails', '~> 3.0'
  gem 'rspec-activemodel-mocks'
  gem 'rubocop'
end

group :test do
  gem 'webmock', require: false
  gem 'capybara'
  gem 'codeclimate-test-reporter', require: nil
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'foreman'
  gem 'brakeman'
end
