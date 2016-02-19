require 'rails_helper'

RSpec.feature 'Auto Deployment' do
  fixtures :all
  let(:github) { instance_double(GitHub::Client) }

  before do
    allow(SlashDeploy.service).to receive(:github).and_return(github)
  end

  scenario 'receiving a `push` event from GitHub when the repo is not enabled for auto deployments' do
    push_event 'secret'
    expect(last_response.status).to eq 200
  end

  scenario 'receiving a `push` event with an invalid secret' do
    push_event 'l33th@cks'
    expect(last_response.status).to eq 403
  end

  scenario 'receiving a `push` event from GitHub when the production environment is configured to auto deploy the master branch' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    environment = repo.environment('production')
    environment.configure_auto_deploy('refs/heads/master')

    expect(github).to receive(:create_deployment).with \
      users(:david),
      DeploymentRequest.new(
        repository: 'baxterthehacker/public-repo',
        ref: '0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c',
        environment: 'production'
      )

    push_event 'secret', sender: { id: github_accounts(:david).id }
  end

  scenario 'receiving a `push` event when the environment is locked' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    environment = repo.environment('production')
    environment.configure_auto_deploy('refs/heads/master')
    environment.lock! users(:david)

    push_event 'secret', sender: { id: github_accounts(:david).id }
  end

  scenario 'receiving a `push` event from GitHub from a user that has never logged into slashdeploy' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    environment = repo.environment('production')
    environment.configure_auto_deploy('refs/heads/master', fallback_user: users(:steve))

    expect(github).to receive(:create_deployment).with \
      users(:steve),
      DeploymentRequest.new(
        repository: 'baxterthehacker/public-repo',
        ref: '0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c',
        environment: 'production'
      )

    push_event 'secret', sender: { id: 1234567 }
  end

  scenario 'receiving a `push` event from GitHub from a user that has never logged into slashdeploy, when there is no fallback' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    environment = repo.environment('production')
    environment.configure_auto_deploy('refs/heads/master')
    expect do
      push_event 'secret', sender: { id: 1234567 }
    end.to raise_error SlashDeploy::NoAutoDeployUser
  end

  scenario 'receiving a `status` event when the repository is configured to deploy on successful commit statuses' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    environment = repo.environment('production')
    environment.required_contexts = ['ci/circleci', 'security/brakeman']
    environment.configure_auto_deploy('refs/heads/master')

    push_event 'secret', sender: { id: github_accounts(:david).id }
    status_event 'secret', context: 'ci/circleci', state: 'pending'
    status_event 'secret', context: 'ci/circleci', state: 'success'

    expect(github).to receive(:create_deployment).with \
      users(:david),
      DeploymentRequest.new(
        repository: 'baxterthehacker/public-repo',
        ref: '0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c',
        environment: 'production'
      )

    status_event 'secret', context: 'security/brakeman', state: 'success'
  end

  scenario 'receiving a `failed` status event' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    environment = repo.environment('production')
    environment.required_contexts = ['ci/circleci', 'security/brakeman']
    environment.configure_auto_deploy('refs/heads/master')

    expect(github).to_not receive(:create_deployment)
    push_event 'secret', sender: { id: github_accounts(:david).id }
    status_event 'secret', context: 'ci/circleci', state: 'pending'
    status_event 'secret', context: 'ci/circleci', state: 'failure'
    status_event 'secret', context: 'security/brakeman', state: 'success'
  end

  scenario 'receiving a new `push` event for a new HEAD of the ref when there is a previous auto deployment' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    environment = repo.environment('production')
    environment.required_contexts = ['ci/circleci', 'security/brakeman']
    environment.configure_auto_deploy('refs/heads/master')

    push_event 'secret', sender: { id: github_accounts(:david).id }
    status_event 'secret', context: 'ci/circleci', state: 'success'
    # Push event for new commit (but same ref).
    push_event 'secret', head_commit: {
      id: 'ac5b9fd6a09a983a3091d4e8292dc32c'
    }, sender: {
      id: github_accounts(:david).id
    }

    expect(github).to_not receive(:create_deployment)
    status_event 'secret', context: 'security/brakeman', state: 'success'
  end

  scenario 'receiving a `push` event for a deleted branch' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    environment = repo.environment('production')
    environment.configure_auto_deploy('refs/heads/master')

    expect(github).to_not receive(:create_deployment)
    push_event 'secret', deleted: true, head_commit: nil
  end

  scenario 'receiving a `push` event for a fork' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    environment = repo.environment('production')
    environment.configure_auto_deploy('refs/heads/master')

    expect(github).to_not receive(:create_deployment)
    push_event 'secret', repository: { fork: true }
  end
end
