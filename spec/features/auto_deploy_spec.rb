require 'rails_helper'

RSpec.feature 'Slash Commands' do
  fixtures :all
  include Rack::Test::Methods
  let(:app) { SlashDeploy.app }

  before do
    deployer.reset
    Repository.create!(name: 'remind101/acme-inc', github_secret: 'secret')
  end

  scenario 'receiving a `push` event from GitHub when the repo is not enabled for auto deployments' do
    event \
      :push,
      'secret',
      ref: 'refs/heads/master',
      repository: {
        full_name: 'remind101/acme-inc'
      }
    expect(last_response.status).to eq 200
  end

  scenario 'receiving a `push` event from GitHub when the production environment is configured to auto deploy the master branch' do
    repo = Repository.with_name('remind101/acme-inc')
    environment = repo.environment('production')
    environment.configure_auto_deploy('refs/heads/master')

    HEAD('remind101/acme-inc', 'master', '338e2fca7e65fa01f41f415b3add48af')

    expect do
      event \
        :push,
        'secret',
        ref: 'refs/heads/master',
        head: '338e2fca7e65fa01f41f415b3add48af',
        repository: {
          full_name: 'remind101/acme-inc'
        },
        sender: {
          id: github_accounts(:david).id
        }
    end.to change { deployment_requests.count }.by(1)
    expect(last_response.status).to eq 200
    expect(deployment_requests).to eq [
      [users(:david), DeploymentRequest.new(repository: 'remind101/acme-inc', ref: '338e2fca7e65fa01f41f415b3add48af', environment: 'production')]
    ]
  end

  scenario 'receiving a `push` event from GitHub from a user that has never logged into slashdeploy' do
    repo = Repository.with_name('remind101/acme-inc')
    environment = repo.environment('production')
    environment.configure_auto_deploy('refs/heads/master', fallback_user: users(:steve))

    HEAD('remind101/acme-inc', 'master', '338e2fca7e65fa01f41f415b3add48af')

    expect do
      event \
        :push,
        'secret',
        ref: 'refs/heads/master',
        head: '338e2fca7e65fa01f41f415b3add48af',
        repository: {
          full_name: 'remind101/acme-inc'
        },
        sender: {
          id: 1234567
        }
    end.to change { deployment_requests.count }.by(1)
    expect(last_response.status).to eq 200
    expect(deployment_requests).to eq [
      [users(:steve), DeploymentRequest.new(repository: 'remind101/acme-inc', ref: '338e2fca7e65fa01f41f415b3add48af', environment: 'production')]
    ]
  end

  def event(event, secret, payload = {})
    body = payload.to_json
    post \
      '/',
      body,
      Hookshot::HEADER_GITHUB_EVENT => event,
      Hookshot::HEADER_HUB_SIGNATURE => "sha1=#{Hookshot.signature(body, secret)}"
  end

  def deployment_requests
    deployer.requests
  end

  def deployer
    SlashDeploy.service.deployer
  end

  # rubocop:disable Style/MethodName
  def HEAD(repository, ref, sha)
    deployer.HEAD(repository, ref, sha)
  end
end
