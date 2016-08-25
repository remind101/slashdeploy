# This module gets included into full stack feature specs in spec/features.
module Features
  GITHUB_EVENTS = %i(status push deployment_status)

  include Rack::Test::Methods

  def app
    Rails.application
  end

  # Runs a / command as the given slack account.
  def command(text, options = {})
    slack_account = options[:as]

    fail "The :as option expects a SlackAccount to be provided, but you provided a #{slack_account.class}." if slack_account && !slack_account.is_a?(SlackAccount)

    command, *text = text.split(/\s/)
    post \
      '/slack/commands',
      command:     command,
      text:        text.join(' '),
      token:       Rails.configuration.x.slack.verification_token,
      user_id:     slack_account.id,
      user_name:   slack_account.user_name,
      team_id:     slack_account.team_id,
      team_domain: slack_account.team_domain
  end

  # Returns the last Slash::Response.
  def command_response
    body = JSON.parse(last_response.body)
    Slash::Response.new(
      message: Slack::Message.new(body),
      in_channel: body['response_type'] == 'in_channel'
    )
  end
  alias_method :action_response, :command_response

  def action(action_value, callback_id, options = {})
    slack_account = options[:as]

    fail "The :as option expects a SlackAccount to be provided, but you provided a #{slack_account.class}." if slack_account && !slack_account.is_a?(SlackAccount)

    post \
      '/slack/actions',
      payload: {
        actions: [
          {
            value: action_value
          }
        ],
        token: Rails.configuration.x.slack.verification_token,
        callback_id: callback_id,
        team: {
          id: slack_account.team_id,
          domain: slack_account.team_domain
        },
        user: {
          id: slack_account.id,
          name: slack_account.user_name
        },
        channel: {
          id: 1,
          name: 'test_channel'
        }
      }.to_json
  end

  # Triggers a github event against SlashDeploy.
  def github_event(event, secret, payload = {})
    body = payload.to_json
    post \
      '/',
      body,
      Hookshot::HEADER_GITHUB_EVENT => event,
      Hookshot::HEADER_HUB_SIGNATURE => "sha1=#{Hookshot.signature(body, secret)}"
  end

  GITHUB_EVENTS.each do |event|
    define_method(:"#{event}_event") do |secret, extra = {}|
      data = fixture("#{event}_event.json")
      github_event event, secret, data.deep_merge(extra.stringify_keys)
    end
  end

  def fixture(name)
    fname = File.expand_path("../fixtures/github/#{name}", __dir__)
    JSON.parse File.read(fname)
  end
end
