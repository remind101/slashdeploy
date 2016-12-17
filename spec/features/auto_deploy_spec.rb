require 'rails_helper'

RSpec.feature 'Auto Deployment' do
  fixtures :all
  let(:github) { instance_double(GitHub::Client) }
  let(:slack) { instance_double(Slack::Client) }

  before do
    allow(SlashDeploy.service).to receive(:github).and_return(github)
    allow(SlashDeploy.service).to receive(:slack).and_return(slack)
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

  scenario 'receiving a `push` event from GitHub when the staging and production environments are configured to auto deploy the master branch' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    production = repo.environment('production')
    production.configure_auto_deploy('refs/heads/master')
    staging = repo.environment('staging')
    staging.configure_auto_deploy('refs/heads/master')

    expect(github).to receive(:create_deployment).with \
      users(:david),
      DeploymentRequest.new(
        repository: 'baxterthehacker/public-repo',
        ref: '0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c',
        environment: 'production'
      )
    expect(github).to receive(:create_deployment).with \
      users(:david),
      DeploymentRequest.new(
        repository: 'baxterthehacker/public-repo',
        ref: '0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c',
        environment: 'staging'
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

    expect(slack).to receive(:direct_message).with \
      slack_accounts(:david_baxterthehacker),
      Slack::Message.new(text: ":wave: <@U012AB1AC>. I'll start a deployment of baxterthehacker/public-repo@0d1a26e to *production* for you once *ci/circleci* and *security/brakeman* are passing.", attachments: [])

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

  scenario 'receiving a `status` event when multiple environments are configured to deploy on successful commit statuses' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    production = repo.environment('production')
    production.required_contexts = ['ci/circleci', 'security/brakeman']
    production.configure_auto_deploy('refs/heads/master')
    staging = repo.environment('staging')
    staging.required_contexts = ['ci/circleci', 'security/brakeman']
    staging.configure_auto_deploy('refs/heads/master')

    expect(slack).to receive(:direct_message).with \
      slack_accounts(:david_baxterthehacker),
      Slack::Message.new(text: ":wave: <@U012AB1AC>. I'll start a deployment of baxterthehacker/public-repo@0d1a26e to *production* for you once *ci/circleci* and *security/brakeman* are passing.", attachments: [])
    expect(slack).to receive(:direct_message).with \
      slack_accounts(:david_baxterthehacker),
      Slack::Message.new(text: ":wave: <@U012AB1AC>. I'll start a deployment of baxterthehacker/public-repo@0d1a26e to *staging* for you once *ci/circleci* and *security/brakeman* are passing.", attachments: [])

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
    expect(github).to receive(:create_deployment).with \
      users(:david),
      DeploymentRequest.new(
        repository: 'baxterthehacker/public-repo',
        ref: '0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c',
        environment: 'staging'
      )

    status_event 'secret', context: 'security/brakeman', state: 'success'
  end

  scenario 'receiving a `failed` status event' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    environment = repo.environment('production')
    environment.required_contexts = ['ci/circleci', 'security/brakeman']
    environment.configure_auto_deploy('refs/heads/master')

    expect(slack).to receive(:direct_message).with \
      slack_accounts(:david_baxterthehacker),
      Slack::Message.new(text: ":wave: <@U012AB1AC>. I'll start a deployment of baxterthehacker/public-repo@0d1a26e to *production* for you once *ci/circleci* and *security/brakeman* are passing.", attachments: [])

    push_event 'secret', sender: { id: github_accounts(:david).id }
    status_event 'secret', context: 'ci/circleci', state: 'pending'
    status_event 'secret', context: 'ci/circleci', state: 'failure'

    expect(slack).to receive(:direct_message).with \
      slack_accounts(:david_baxterthehacker),
      Slack::Message.new(text: ':wave: <@U012AB1AC>. I was going to deploy baxterthehacker/public-repo@0d1a26e to *production* for you, but some required commit status contexts failed.', attachments: [
        Slack::Attachment.new(title: 'ci/circleci', title_link: 'https://ci.com/tests', text: 'Tests passed', color: '#F00', mrkdwn_in: ['text']),
        Slack::Attachment.new(pretext: "_I'll try deploying again when you fix the issues above._", mrkdwn_in: ['pretext'])
      ])
    status_event 'secret', context: 'security/brakeman', state: 'success'

    # So, maybe the user triggers a new build manually.
    expect(github).to receive(:create_deployment).with \
      users(:david),
      DeploymentRequest.new(
        repository: 'baxterthehacker/public-repo',
        ref: '0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c',
        environment: 'production'
      )
    status_event 'secret', context: 'ci/circleci', state: 'success'
  end

  scenario 'receiving a `failed` and `errored` status event' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    environment = repo.environment('production')
    environment.required_contexts = ['ci/circleci', 'security/brakeman']
    environment.configure_auto_deploy('refs/heads/master')

    expect(slack).to receive(:direct_message).with \
      slack_accounts(:david_baxterthehacker),
      Slack::Message.new(text: ":wave: <@U012AB1AC>. I'll start a deployment of baxterthehacker/public-repo@0d1a26e to *production* for you once *ci/circleci* and *security/brakeman* are passing.", attachments: [])

    push_event 'secret', sender: { id: github_accounts(:david).id }
    status_event 'secret', context: 'ci/circleci', state: 'pending'
    status_event 'secret', context: 'ci/circleci', state: 'failure'

    expect(slack).to receive(:direct_message).with \
      slack_accounts(:david_baxterthehacker),
      Slack::Message.new(text: ':wave: <@U012AB1AC>. I was going to deploy baxterthehacker/public-repo@0d1a26e to *production* for you, but some required commit status contexts failed.', attachments: [
        Slack::Attachment.new(title: 'ci/circleci', title_link: 'https://ci.com/tests', text: 'Tests passed', color: '#F00', mrkdwn_in: ['text']),
        Slack::Attachment.new(title: 'security/brakeman', title_link: 'https://ci.com/tests', text: 'Tests passed', color: '#F00', mrkdwn_in: ['text']),
        Slack::Attachment.new(pretext: "_I'll try deploying again when you fix the issues above._", mrkdwn_in: ['pretext'])
      ])
    status_event 'secret', context: 'security/brakeman', state: 'error'

    status_event 'secret', context: 'ci/circleci', state: 'pending'
    status_event 'secret', context: 'security/brakeman', state: 'pending'

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

  scenario 'receiving a new `push` event for a new HEAD of the ref when there is a previous auto deployment' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    environment = repo.environment('production')
    environment.required_contexts = ['ci/circleci', 'security/brakeman']
    environment.configure_auto_deploy('refs/heads/master')

    commits = {
      # Commit #1
      a: '595ebd4ca061c4671ba89202aaf19c896f216635',
      # Commit #2
      b: '819d3357224b257d3589c49f82dae95b761f210a',
      # Commit #3
      c: '364d2a5e074c64b0dc1fe5cba2f428146d154a32'
    }

    expect(slack).to receive(:direct_message).with \
      slack_accounts(:david_baxterthehacker),
      Slack::Message.new(text: ":wave: <@U012AB1AC>. I'll start a deployment of baxterthehacker/public-repo@595ebd4 to *production* for you once *ci/circleci* and *security/brakeman* are passing.", attachments: [])

    # This will simulate the first commit. The auto deployment for this will
    # eventually get canceled, because the commit status contexts are slow.
    push_event 'secret', head_commit: {
      id: commits[:a]
    }, sender: {
      id: github_accounts(:david).id
    }

    expect(slack).to receive(:direct_message).with \
      slack_accounts(:david_baxterthehacker),
      Slack::Message.new(text: ":wave: <@U012AB1AC>. I'll start a deployment of baxterthehacker/public-repo@819d335 to *production* for you once *ci/circleci* and *security/brakeman* are passing.", attachments: [])

    # Push the second commit
    push_event 'secret', head_commit: {
      id: commits[:b]
    }, sender: { id: github_accounts(:david).id }

    # Tests start passing on the second commit.
    status_event 'secret', sha: commits[:b], context: 'ci/circleci', state: 'success'

    expect(slack).to receive(:direct_message).with \
      slack_accounts(:david_baxterthehacker),
      Slack::Message.new(text: ":wave: <@U012AB1AC>. I'll start a deployment of baxterthehacker/public-repo@364d2a5 to *production* for you once *ci/circleci* and *security/brakeman* are passing.", attachments: [])

    # Push the third commit.
    push_event 'secret', head_commit: {
      id: commits[:c]
    }, sender: {
      id: github_accounts(:david).id
    }

    # security/brakemen passes on second commit, triggers a deploy.
    expect(github).to receive(:create_deployment).with(
      users(:david),
      DeploymentRequest.new(
        repository: 'baxterthehacker/public-repo',
        ref: commits[:b],
        environment: 'production'
      )
    )
    status_event 'secret', sha: commits[:b], context: 'security/brakeman', state: 'success'

    # Everything passes on the third commit and triggers a deploy.
    expect(github).to receive(:create_deployment).with(
      users(:david),
      DeploymentRequest.new(
        repository: 'baxterthehacker/public-repo',
        ref: commits[:c],
        environment: 'production'
      )
    )
    status_event 'secret', sha: commits[:c], context: 'ci/circleci', state: 'success'
    status_event 'secret', sha: commits[:c], context: 'security/brakeman', state: 'success'

    # Commit statuses finally come in for the first commit, but since the second commit was already deployed, it's a noop.
    expect(github).to_not receive(:create_deployment)
    status_event 'secret', sha: commits[:a], context: 'ci/circleci', state: 'success'
    status_event 'secret', sha: commits[:a], context: 'security/brakeman', state: 'success'
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
