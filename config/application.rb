require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SlashDeploy
  class Application < Rails::Application
    # Sane logging.
    config.lograge.enabled = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # https://devcenter.heroku.com/articles/rails-4-asset-pipeline#serve-assets
    config.serve_static_files = true

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.autoload_paths << Rails.root.join('lib')

    # Dump schema in sql format.
    config.active_record.schema_format = :sql

    require 'rack/statsd'
    config.middleware.insert_before 0, Rack::StatsD
    config.middleware.use Warden::Manager do |config|
    end

    require 'perty'
    config.middleware.swap Rails::Rack::Logger, Perty::Rack

    # The name of the deployment backend to use. Possible options are:
    #   
    #   github
    config.x.github_client = ENV['GITHUB_CLIENT']
    # The name of the slack backend to use. Possible options are:
    #
    #   slack
    config.x.slack_client = ENV['SLACK_CLIENT']
    config.x.default_environment = 'production'
    config.x.default_ref = 'master'
    config.x.feedback_email = 'hi@slashdeploy.io'

    # While we're in beta mode...
    config.x.beta = ENV['BETA'].present?

    # Segment.io
    config.x.segment.write_key = ENV['SEGMENT_KEY']

    # The shared token between slack and SlashDeploy. Used to verify that slash
    # commands actually came from Slack.
    config.x.slack.verification_token = ENV['SLACK_VERIFICATION_TOKEN']

    config.middleware.use OmniAuth::Builder do
      provider \
        :github,
        ENV['GITHUB_CLIENT_ID'],
        ENV['GITHUB_CLIENT_SECRET'],
        scope: 'repo_deployment'
      provider \
        :slack,
        ENV['SLACK_CLIENT_ID'],
        ENV['SLACK_CLIENT_SECRET'],
        scope: 'identify',
        setup: lambda { |env|
          request = Rack::Request.new(env)
          env['omniauth.strategy'].options[:scope] = request.params['scope'] if request.params['scope'].present?
        }
    end
  end
end

require 'slashdeploy'
