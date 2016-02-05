require 'rails_helper'

RSpec.feature 'Slash Commands' do
  fixtures :all
  include Rack::Test::Methods
  let(:app) { SlashDeploy.app }

  before do
    deployment_requests.clear
  end

  scenario 'authenticating' do
    stub_request(:post, 'https://github.com/login/oauth/access_token')
      .with(body: { 'client_id' => '', 'client_secret' => '', 'code' => 'code', 'grant_type' => 'authorization_code' })
      .to_return(status: 200, body: { 'access_token' => 'e72e16c7e42f292c6912e7710c838347ae178b4a', 'scope' => 'repo_deployment', 'token_type' => 'bearer' }.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'https://api.github.com/user')
      .to_return(status: 200, body: { 'id' => 1, 'login' => 'joe' }.to_json, headers: { 'Content-Type' => 'application/json' })

    account = SlackAccount.new(
      id: 'UABCD',
      user_name: 'joe',
      team_id: 1,
      team_domain: 'acme'
    )
    command '/deploy help', as: account
    state = response.text.gsub(/^.*state=(.*?)\|.*$/, '\\1')
    get '/auth/github/callback', state: state, code: 'code'
  end

  scenario 'entering an unknown command' do
    command '/deploy foo', as: slack_accounts(:david)
    expect(response.text).to eq "I don't know that command. Here's what I do know:\n#{HelpCommand::USAGE}".strip
  end

  scenario 'performing a simple deployment' do
    command '/deploy remind101/acme-inc', as: slack_accounts(:david)
    expect(deployment_requests).to eq [
      [users(:david), DeploymentRequest.new(repository: 'remind101/acme-inc', ref: 'master', environment: 'production')]
    ]
  end

  scenario 'performing a deployment to a specific environment' do
    command '/deploy remind101/acme-inc to staging', as: slack_accounts(:david)
    expect(deployment_requests).to eq [
      [users(:david), DeploymentRequest.new(repository: 'remind101/acme-inc', ref: 'master', environment: 'staging')]
    ]
  end

  scenario 'performing a deployment of a topic branch' do
    command '/deploy remind101/acme-inc@topic', as: slack_accounts(:david)
    expect(deployment_requests).to eq [
      [users(:david), DeploymentRequest.new(repository: 'remind101/acme-inc', ref: 'topic', environment: 'production')]
    ]
  end

  scenario 'performing a deployment of a branch that has failing commit status contexts' do
    expect do
      command '/deploy remind101/acme-inc@failing', as: slack_accounts(:david)
    end.to_not change { deployment_requests }

    expect(response.text).to eq <<-EOF.strip
The following commit status checks failed:
* ci
You can ignore commit status checks by using `/deploy remind101/acme-inc@failing!`
EOF

    expect do
      command '/deploy remind101/acme-inc@failing!', as: slack_accounts(:david)
    end.to change { deployment_requests.count }.by(1)
  end

  scenario 'locking a branch' do
    command '/deploy lock staging on remind101/acme-inc', as: slack_accounts(:david)
    expect(response.text).to eq 'Locked `staging` on remind101/acme-inc'

    # Other users shouldn't be able to deploy now.
    expect do
      command '/deploy remind101/acme-inc to staging', as: slack_accounts(:steve)
    end.to_not change { deployment_requests }
    expect(response.text).to eq '`staging` is locked by @david'

    # But david should be able to deploy.
    expect do
      command '/deploy remind101/acme-inc to staging', as: slack_accounts(:david)
    end.to change { deployment_requests.count }.by(1)
  end

  scenario 'stealing a lock' do
    command '/deploy lock staging on remind101/acme-inc', as: slack_accounts(:david)
    expect(response.text).to eq 'Locked `staging` on remind101/acme-inc'

    command '/deploy lock staging on remind101/acme-inc', as: slack_accounts(:david)
    expect(response.text).to eq '`staging` is already locked'

    command '/deploy lock staging on remind101/acme-inc', as: slack_accounts(:steve)
    expect(response.text).to eq 'Locked `staging` on remind101/acme-inc (stolen from @david)'

    expect do
      command '/deploy remind101/acme-inc to staging', as: slack_accounts(:david)
    end.to_not change { deployment_requests }
  end

  def deployment_requests
    SlashDeploy.service.deployer.requests
  end

  def command(text, options = {})
    slack_account = options[:as]

    command, *text = text.split(' ')
    post \
      '/commands',
      command:     command,
      text:        text.join(' '),
      token:       Rails.configuration.x.slack.verification_token,
      user_id:     slack_account.id,
      user_name:   slack_account.user_name,
      team_id:     slack_account.team_id,
      team_domain: slack_account.team_domain
  end

  def response
    body = JSON.parse(last_response.body)
    Slash::Response.new(
      text: body['text'],
      in_channel: body['response_type'] == 'in_channel'
    )
  end
end
