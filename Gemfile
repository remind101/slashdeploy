source 'https://rubygems.org'

ruby '2.5.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.2.10'
gem 'uglifier', '>= 1.3.0'
gem 'jquery-rails'
gem 'turbolinks'
gem 'virtus'
gem 'pg', '~> 0.21'
gem 'postgres_ext'
gem 'oj'
gem 'puma'
gem 'sass'
gem 'therubyracer'

# Not actually used, but Rails asset pipeline (sprockets) is loading it.
# TODO: Try to remove with config.generators.javascript_engine = :js
gem 'coffee-script'

# Github API Client Library.
gem 'octokit', '>= 4.9.0'

# Used for interacting with Slack API.
gem 'faraday', '0.9.1'
gem 'faraday_middleware'

# async worker.
gem 'sidekiq'

# Visibility
gem 'rollbar', '~> 2.8.0'
gem 'lograge'
gem 'dogstatsd-ruby', '~> 1.5.0'

# Auth
gem 'jwt'
gem 'warden'
gem 'oauth2'
gem 'omniauth'
gem 'omniauth-oauth2'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'rspec', '~> 3.7.0'
  gem 'rspec-rails'
  gem 'rspec-activemodel-mocks'
  gem 'rubocop', '~> 0.58.0'

  gem 'pry',                       '0.10.3'
  gem 'pry-rails',                 '0.3.4'
end

group :test do
  gem 'webmock', require: false
  gem 'capybara'
  gem 'codeclimate-test-reporter', '0.4.8', require: nil
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'foreman'
  gem 'brakeman'
  gem 'dotenv-rails', '~> 2.2'
end
