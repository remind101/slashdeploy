require 'rails_helper'

RSpec.feature 'Slash Commands' do
  fixtures :all

  before do
    github.reset

    # Set the HEAD commits for some fake branches.
    HEAD('acme-inc/api', 'master',  'ad80a1b3e1a94b98ce99b71a48f811f1')
    HEAD('acme-inc/api', 'topic',   '4c7b474c6e1c81553a16d1082cebfa60')
    HEAD('acme-inc/api', 'failing', '46c2acc4e588924340adcd108cfc948b')
  end

  scenario 'authenticating' do
    stub_request(:post, 'https://github.com/login/oauth/access_token')
      .with(body: { 'client_id' => '', 'client_secret' => '', 'code' => 'code', 'grant_type' => 'authorization_code' })
      .to_return(status: 200, body: { 'access_token' => 'e72e16c7e42f292c6912e7710c838347ae178b4a', 'scope' => 'repo_deployment', 'token_type' => 'bearer' }.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'https://api.github.com/user')
      .to_return(status: 200, body: { 'id' => 1, 'login' => 'joe' }.to_json, headers: { 'Content-Type' => 'application/json' })

    account = SlackAccount.new(
      id:         'UABCD',
      user_name:  'joe',
      slack_team: slack_teams(:acme)
    )

    command '/deploy help', as: account
    state = command_response.text.gsub(/^.*state=(.*?)\|.*$/, '\\1')
    expect do
      visit "/auth/github/callback?state=#{state}&code=code"
    end.to change { User.count }.by(1)

    command '/deploy help', as: account
    expect(command_response.text).to eq HelpMessage::USAGE.strip
  end

  scenario 'entering an unknown command' do
    command '/deploy foo', as: slack_accounts(:bob)
    expect(command_response.in_channel).to be_falsey
    expect(command_response.message).to eq Slack::Message.new(text: "I don't know that command. Here's what I do know:\n#{HelpMessage::USAGE}".strip)
  end

  scenario 'performing a simple deployment' do
    command '/deploy  acme-inc/api to production', as: slack_accounts(:david)
    expect(deployment_requests).to eq [
      [users(:david), DeploymentRequest.new(repository: 'acme-inc/api', ref: 'master', environment: 'production')]
    ]
    expect(command_response).to be_in_channel
    expect(command_response.message).to eq Slack::Message.new(text: 'Created deployment request for <https://github.com/acme-inc/api|acme-inc/api>@<https://github.com/acme-inc/api/commits/ad80a1b3e1a94b98ce99b71a48f811f1|master> to *production* (no change)')

    # David commits something new
    HEAD('acme-inc/api', 'master', 'f5c0df18526b90b9698816ee4b6606e0')

    command '/deploy acme-inc/api to production', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Created deployment request for <https://github.com/acme-inc/api|acme-inc/api>@<https://github.com/acme-inc/api/commits/f5c0df18526b90b9698816ee4b6606e0|master> to *production* (<https://github.com/acme-inc/api/compare/ad80a1b...f5c0df1|diff>)')
  end

  scenario 'performing a deployment to a specific environment' do
    command '/deploy acme-inc/api  to staging', as: slack_accounts(:david)
    expect(deployment_requests).to eq [
      [users(:david), DeploymentRequest.new(repository: 'acme-inc/api', ref: 'master', environment: 'staging')]
    ]
  end

  scenario 'performing a deployment to an aliased environment' do
    repo = Repository.with_name('acme-inc/api')
    env  = repo.environment('staging')
    env.aliases = ['stage']
    env.save!

    command '/deploy acme-inc/api to stage', as: slack_accounts(:david)
    expect(deployment_requests).to eq [
      [users(:david), DeploymentRequest.new(repository: 'acme-inc/api', ref: 'master', environment: 'staging')]
    ]
  end

  scenario 'performing a deployment using only the repo name' do
    command '/deploy api@topic to production', as: slack_accounts(:david)
    expect(deployment_requests).to eq [
      [users(:david), DeploymentRequest.new(repository: 'acme-inc/api', ref: 'topic', environment: 'production')]
    ]
  end

  scenario 'performing a deployment of a topic branch' do
    command '/deploy acme-inc/api@topic to production', as: slack_accounts(:david)
    expect(deployment_requests).to eq [
      [users(:david), DeploymentRequest.new(repository: 'acme-inc/api', ref: 'topic', environment: 'production')]
    ]
  end

  scenario 'performing a deployment of a branch that has failing commit status contexts' do
    expect do
      command '/deploy acme-inc/api@failing to production', as: slack_accounts(:david)
    end.to_not change { deployment_requests }

    expect(command_response.message).to eq Slack::Message.new(text: <<-TEXT.strip_heredoc.strip)
    The following commit status checks failed:
    * ci
    You can ignore commit status checks by using `/deploy acme-inc/api@failing to production!`
    TEXT

    expect do
      command '/deploy acme-inc/api@failing to production!', as: slack_accounts(:david)
    end.to change { deployment_requests.count }.by(1)
  end

  scenario 'attempting to deploy a repo I do not have access to' do
    command '/deploy acme-inc/api to production', as: slack_accounts(:bob)
    expect(command_response.message).to eq Slack::Message.new(text: "Sorry, but it looks like you don't have access to acme-inc/api")
  end

  scenario 'attempting to deploy a ref that does not exist on github' do
    command '/deploy acme-inc/api@non-existent-branch to production', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'The ref `non-existent-branch` was not found in acme-inc/api')
  end

  scenario 'locking a branch' do
    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Locked *staging* on acme-inc/api')

    # Other users shouldn't be able to deploy now.
    expect(SecureRandom).to receive(:uuid).and_return('a1a111a1-1111-1a1a-a1a1-111aaa111111').at_least(:once)
    expect do
      command '/deploy acme-inc/api to staging', as: slack_accounts(:steve)
    end.to_not change { deployment_requests }
    expect(command_response.message).to eq Slack::Message.new(text: "*staging* was locked by <@david> less than a minute ago.\nYou can steal the lock with `/deploy lock staging on acme-inc/api!`.", attachments: steal_lock_attachments)

    # But david should be able to deploy.
    expect do
      command '/deploy acme-inc/api to staging', as: slack_accounts(:david)
    end.to change { deployment_requests.count }.by(1)

    command '/deploy unlock staging on acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Unlocked *staging* on acme-inc/api')

    # Now other users should be able to deploy
    expect do
      command '/deploy acme-inc/api to staging', as: slack_accounts(:steve)
    end.to change { deployment_requests.count }.by(1)
  end

  scenario 'locking a branch with a message' do
    command "/deploy lock staging on acme-inc/api: I'm testing some stuff", as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Locked *staging* on acme-inc/api')

    # Other users shouldn't be able to deploy now.
    expect(SecureRandom).to receive(:uuid).and_return('a1a111a1-1111-1a1a-a1a1-111aaa111111').at_least(:once)
    expect do
      command '/deploy acme-inc/api to staging', as: slack_accounts(:steve)
    end.to_not change { deployment_requests }
    expect(command_response.message).to eq Slack::Message.new(text: "*staging* was locked by <@david> less than a minute ago.\n> I'm testing some stuff\nYou can steal the lock with `/deploy lock staging on acme-inc/api!`.", attachments: steal_lock_attachments)
  end

  scenario 'stealing a lock' do
    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Locked *staging* on acme-inc/api')

    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: '*staging* is already locked')

    expect(SecureRandom).to receive(:uuid).and_return('a1a111a1-1111-1a1a-a1a1-111aaa111111').at_least(:once)
    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:steve)
    expect(command_response.message).to eq Slack::Message.new(text: "*staging* was locked by <@david> less than a minute ago.\nYou can steal the lock with `/deploy lock staging on acme-inc/api!`.", attachments: steal_lock_attachments)

    expect do
      command '/deploy acme-inc/api to staging', as: slack_accounts(:steve)
    end.to_not change { deployment_requests }

    command '/deploy lock staging on acme-inc/api!', as: slack_accounts(:steve)
    expect(command_response.message).to eq Slack::Message.new(text: 'Locked *staging* on acme-inc/api (stolen from <@david>)')

    expect do
      command '/deploy acme-inc/api to staging', as: slack_accounts(:david)
    end.to_not change { deployment_requests }
  end

  scenario 'trying to do something on a repo I dont have access to' do
    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:bob)
    expect(command_response.message).to eq Slack::Message.new(text: "Sorry, but it looks like you don't have access to acme-inc/api")
  end

  scenario 'finding the environments I can deploy a repo to' do
    command '/deploy where acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: "I don't know about any environments for acme-inc/api")

    command '/deploy acme-inc/api to staging', as: slack_accounts(:david)

    command '/deploy where acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: <<-TEXT.strip_heredoc.strip)
    I know about these environments for acme-inc/api:
    * staging
    TEXT
  end

  scenario 'trying to /deploy to an invalid repoisotory' do
    expect do
      command '/deploy acme-inc/$api@master to production', as: slack_accounts(:david)
    end.to_not change { deployment_requests }
    expect(command_response.message).to eq Slack::Message.new(
      text: 'Oops! We had a problem running that command for you.',
      attachments: [
        Slack::Attachment.new(color: '#f00', fields: [
          Slack::Attachment::Field.new(title: 'repository name', value: 'not a valid GitHub repository')
        ])
      ]
    )
  end

  scenario 'trying to /deploy with no environment, when the repository does not have a default' do
    expect do
      command '/deploy acme-inc/api@master', as: slack_accounts(:david)
    end.to_not change { deployment_requests }
    expect(command_response.message).to eq Slack::Message.new(
      text: 'Oops! We had a problem running that command for you.',
      attachments: [
        Slack::Attachment.new(color: '#f00', fields: [
          Slack::Attachment::Field.new(title: 'environment name', value: "can't be blank")
        ])
      ]
    )
  end

  scenario 'trying to /deploy an environment that is configured to auto deploy' do
    repo = Repository.with_name('acme-inc/api')
    repo.update_attributes! default_environment: 'production'
    environment = repo.environment('production')
    environment.configure_auto_deploy('refs/heads/master')

    expect do
      command '/deploy acme-inc/api@master', as: slack_accounts(:david)
    end.to_not change { deployment_requests }
    expect(command_response.message).to eq Slack::Message.new(text: "acme-inc/api is configured to automatically deploy `refs/heads/master` to *production*.\nYou can bypass this warning with `/deploy acme-inc/api@master!`")

    expect do
      command '/deploy acme-inc/api@master!', as: slack_accounts(:david)
    end.to change { deployment_requests.count }.by(1)
  end

  scenario 'stealing a lock by action' do
    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Locked *staging* on acme-inc/api')

    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: '*staging* is already locked')

    expect(SecureRandom).to receive(:uuid).and_return('a1a111a1-1111-1a1a-a1a1-111aaa111111').at_least(:once)
    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:steve)
    expect(command_response.message).to eq Slack::Message.new(text: "*staging* was locked by <@david> less than a minute ago.\nYou can steal the lock with `/deploy lock staging on acme-inc/api!`.", attachments: steal_lock_attachments)

    expect do
      command '/deploy acme-inc/api to staging', as: slack_accounts(:steve)
    end.to_not change { deployment_requests }

    expect do # Action declined
      action 'no', 'a1a111a1-1111-1a1a-a1a1-111aaa111111', as: slack_accounts(:steve)
    end.to_not change { deployment_requests }
    expect(action_response.message).to eq Slack::Message.new(text: 'Did not steal lock.')

    action 'yes', 'a1a111a1-1111-1a1a-a1a1-111aaa111111', as: slack_accounts(:steve)
    expect(action_response.message).to eq Slack::Message.new(text: 'Locked *staging* on acme-inc/api (stolen from <@david>)')

    expect do
      command '/deploy acme-inc/api to staging', as: slack_accounts(:david)
    end.to_not change { deployment_requests }
  end

  scenario 'trying to perform an action that does not exist' do
    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Locked *staging* on acme-inc/api')

    expect do
      action 'yes', 'b1b111b1-1111-1b1b-b1b1-111bbb111111', as: slack_accounts(:steve)
    end.to_not change { deployment_requests }
    expect(action_response.message).to eq Slack::Message.new(text: "Oops! We had a problem running your command, but we've been notified")
  end

  scenario 'trying to perform an action that is not whitelisted' do
    MessageAction.create!(
      callback_id: 'b1b111b1-1111-1b1b-b1b1-111bbb111111',
      action_params: '{}',
      action: SlashDeploy::Auth.name
    )
    expect do # Unregistered action
      action 'yes', 'b1b111b1-1111-1b1b-b1b1-111bbb111111', as: slack_accounts(:steve)
    end.to_not change { deployment_requests }
    expect(action_response.message).to eq Slack::Message.new(text: "Oops! We had a problem running your command, but we've been notified")
  end

  xscenario 'debugging exception tracking' do
    command '/deploy boom', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: "Oops! We had a problem running your command, but we've been notified")
  end

  def deployment_requests
    github.requests
  end

  def github
    SlashDeploy.service.github
  end

  # rubocop:disable Style/MethodName
  def HEAD(repository, ref, sha)
    github.HEAD(repository, ref, sha)
  end

  def steal_lock_attachments
    [
      Slack::Attachment.new(
        mrkdwn_in: ['text'],
        callback_id: 'a1a111a1-1111-1a1a-a1a1-111aaa111111',
        color: '#3AA3E3',
        actions: [
          Slack::Attachment::Action.new(
            name: 'yes',
            text: 'Yes',
            type: 'button',
            style: 'primary',
            value: 'yes'),
          Slack::Attachment::Action.new(
            name: 'no',
            text: 'No',
            type: 'button',
            value: 'no')
        ]
      )
    ]
  end
end
