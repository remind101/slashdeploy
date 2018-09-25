require 'rails_helper'

RSpec.feature 'Slash Commands' do
  fixtures :all

  before do
    github.reset
    # slack.reset

    # Set the HEAD commits for some fake branches.
    HEAD('acme-inc/api', 'master',  'ad80a1b3e1a94b98ce99b71a48f811f1')
    HEAD('acme-inc/api', 'topic',   '4c7b474c6e1c81553a16d1082cebfa60')
    HEAD('acme-inc/api', 'failing', '46c2acc4e588924340adcd108cfc948b')
  end

  after do
    OmniAuth.config.mock_auth[:github] = nil
  end

  scenario 'authenticating' do
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: 'github',
      uid: '123545',
      info: {
        nickname: 'joe'
      },
      credentials: {
        token: 'e72e16c7e42f292c6912e7710c838347ae178b4a'
      }
    )

    account = SlackAccount.new(
      id:         'UABCD',
      user_name:  'joe',
      slack_team: slack_teams(:acme)
    )

    # This is the first time this user ran a slash deploy command.
    # This user does not have an associated Github account so
    # we bubble and resue MissingGitHubAccount. During the rescue we
    # send a slack notification to the user with a link to install slashdeploy
    # as an oauth app on their github user.
    command '/deploy help', as: account

    OmniAuth.config.mock_auth[:jwt] = OmniAuth::AuthHash.new(
      provider: 'jwt',
      uid: User.find_by_slack('UABCD').id
    )

    # simulate clicking the oauth link.
    expect do
      visit command_response.text.match(%r{^.*(/auth/jwt/callback\?jwt=.*?)\|.*$})[1]
    end.to_not change { User.count }

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
    command '/deploy acme-inc/api to staging', as: slack_accounts(:david)
    expect(deployment_requests).to eq [
      [users(:david), DeploymentRequest.new(repository: 'acme-inc/api', ref: 'master', environment: 'staging')]
    ]
  end

  scenario 'performing a deployment to an aliased environment' do
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

  scenario 'performing a deployment to an unknown environment' do
    command '/deploy baxterthehacker/public-repo to production', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: "I don't know about any environments for baxterthehacker/public-repo. For details about configuring environments, see <https://slashdeploy.io/docs>.")
  end

  scenario 'performing a deployment of a topic branch' do
    command '/deploy acme-inc/api@topic to production', as: slack_accounts(:david)
    expect(deployment_requests).to eq [
      [users(:david), DeploymentRequest.new(repository: 'acme-inc/api', ref: 'topic', environment: 'production')]
    ]

    callback_id = command_response.message.attachments[0].callback_id
    expect(command_response.message).to eq Slack::Message.new(
      text: 'Created deployment request for <https://github.com/acme-inc/api|acme-inc/api>@<https://github.com/acme-inc/api/commits/4c7b474c6e1c81553a16d1082cebfa60|topic> to *production* (no change)',
      attachments: [
        Slack::Attachment.new(
          mrkdwn_in: ['text'],
          title: 'Lock production?',
          text: 'The default ref for *production* is `master`, but you deployed `topic`.',
          callback_id: callback_id,
          color: '#3AA3E3',
          actions: SlackMessage.confirmation_actions
        )
      ]
    )
  end

  scenario 'performing a deployment of a topic branch and locking via the message button' do
    command '/deploy acme-inc/api@topic to production', as: slack_accounts(:david)
    expect(deployment_requests).to eq [
      [users(:david), DeploymentRequest.new(repository: 'acme-inc/api', ref: 'topic', environment: 'production')]
    ]

    callback_id = command_response.message.attachments[0].callback_id
    expect(command_response.message).to eq Slack::Message.new(
      text: 'Created deployment request for <https://github.com/acme-inc/api|acme-inc/api>@<https://github.com/acme-inc/api/commits/4c7b474c6e1c81553a16d1082cebfa60|topic> to *production* (no change)',
      attachments: [
        Slack::Attachment.new(
          mrkdwn_in: ['text'],
          title: 'Lock production?',
          text: 'The default ref for *production* is `master`, but you deployed `topic`.',
          callback_id: callback_id,
          color: '#3AA3E3',
          actions: SlackMessage.confirmation_actions
        )
      ]
    )

    action 'yes', callback_id, as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Locked *production* on acme-inc/api')

    command '/deploy check production on acme-inc/api', as: slack_accounts(:david)

    attachment = Slack::Attachment.new(
      mrkdwn_in: ['text'],
      color: '#F00',
      title: 'Lock Status',
      text: '*production* was locked by <@U012AB1AB> less than a minute ago.'
    )
    expect(command_response.message).to eq Slack::Message.new(text: 'acme-inc/api (*production*)', attachments: [attachment])

    # Once we're holding the lock, we shouldn't be asked to lock it again.
    command '/deploy acme-inc/api@topic to production', as: slack_accounts(:david)
    expect(deployment_requests).to eq [
      [users(:david), DeploymentRequest.new(repository: 'acme-inc/api', ref: 'topic', environment: 'production')],
      [users(:david), DeploymentRequest.new(repository: 'acme-inc/api', ref: 'topic', environment: 'production')]
    ]

    expect(command_response.message).to eq Slack::Message.new(
      text: 'Created deployment request for <https://github.com/acme-inc/api|acme-inc/api>@<https://github.com/acme-inc/api/commits/4c7b474c6e1c81553a16d1082cebfa60|topic> to *production* (no change)'
    )
  end

  scenario 'performing a deployment of a topic branch and then re-deploying the default ref' do
    command '/deploy acme-inc/api@topic to production', as: slack_accounts(:david)
    expect(deployment_requests).to eq [
      [users(:david), DeploymentRequest.new(repository: 'acme-inc/api', ref: 'topic', environment: 'production')]
    ]

    callback_id = command_response.message.attachments[0].callback_id
    expect(command_response.message).to eq Slack::Message.new(
      text: 'Created deployment request for <https://github.com/acme-inc/api|acme-inc/api>@<https://github.com/acme-inc/api/commits/4c7b474c6e1c81553a16d1082cebfa60|topic> to *production* (no change)',
      attachments: [
        Slack::Attachment.new(
          mrkdwn_in: ['text'],
          title: 'Lock production?',
          text: 'The default ref for *production* is `master`, but you deployed `topic`.',
          callback_id: callback_id,
          color: '#3AA3E3',
          actions: SlackMessage.confirmation_actions
        )
      ]
    )

    action 'yes', callback_id, as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Locked *production* on acme-inc/api')

    command '/deploy acme-inc/api@master to production', as: slack_accounts(:david)

    callback_id = command_response.message.attachments[0].callback_id
    expect(command_response.message).to eq Slack::Message.new(
      text: 'Created deployment request for <https://github.com/acme-inc/api|acme-inc/api>@<https://github.com/acme-inc/api/commits/ad80a1b3e1a94b98ce99b71a48f811f1|master> to *production* (<https://github.com/acme-inc/api/compare/4c7b474...ad80a1b|diff>)',
      attachments: [
        Slack::Attachment.new(
          mrkdwn_in: ['text'],
          title: 'Unlock production?',
          text: 'You just deployed the default ref for *production*. Do you want to unlock it?',
          callback_id: callback_id,
          color: '#3AA3E3',
          actions: SlackMessage.confirmation_actions
        )
      ]
    )

    action 'yes', callback_id, as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Unlocked *production* on acme-inc/api')
  end

  scenario 'david locks two environments and then runs unlock all' do
    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Locked *staging* on acme-inc/api')
    command '/deploy lock production on acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Locked *production* on acme-inc/api')
    expect(users(:david).locks.active.count).to eq 2
    command '/deploy unlock all', as: slack_accounts(:david)
    expect(users(:david).locks.active.count).to eq 0
    expect(command_response.message).to eq Slack::Message.new(text: <<-TEXT.strip_heredoc.strip)
    You unlocked all of the the following:
     * *staging* on acme-inc/api
     * *production* on acme-inc/api
    TEXT
    
  end

  scenario 'david locks an environment and forgets' do
    # make sure our queue is clear before starting test.
    LockNagWorker.clear

    # our lock nag worker should to start with an empty queue.
    expect(LockNagWorker.jobs.size).to eq 0

    # simulate david locking stage on acme-inc/api
    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Locked *staging* on acme-inc/api')

    # our lock nag worker should increase by 1.
    expect(LockNagWorker.jobs.size).to eq 1

    # setup expectations of the worker should notify (nag) the user about the forgotten lock.
    expect(slack).to receive(:direct_message).with(
      slack_accounts(:david),
      any_args
    )

    # simulate waiting 3 days and drain worker early to trigger nag.
    LockNagWorker.perform_one

    # our lock nag worker should still be 1.
    expect(LockNagWorker.jobs.size).to eq 1

    # simulate david unlocking stage on acme-inc/api
    command '/deploy unlock staging on acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Unlocked *staging* on acme-inc/api')

    # simulate waiting 3 more days and drain worker early to trigger nag.
    LockNagWorker.perform_one

    # our lock nag worker should be 0, the lock was not active
    # and the user should not be nagged anymore.
    expect(LockNagWorker.jobs.size).to eq 0
  end

  scenario 'performing a deployment of a branch that has failing commit status contexts' do
    expect do
      command '/deploy acme-inc/api@failing to production', as: slack_accounts(:david)
    end.to_not change { deployment_requests }

    callback_id = command_response.message.attachments[0].callback_id
    expect(command_response.message).to eq Slack::Message.new(text: <<-TEXT.strip_heredoc.strip, attachments: [Slack::Attachment.new(title: 'Ignore status checks and deploy anyway?', callback_id: callback_id, color: '#3AA3E3', actions: SlackMessage.confirmation_actions)])
    The following commit status checks are not passing:
    * *ci* [failure]
    TEXT

    expect do
      command '/deploy acme-inc/api@failing to production!', as: slack_accounts(:david)
    end.to change { deployment_requests.count }.by(1)
  end

  scenario 'performing a deployment of a branch that has pending commit status contexts' do
    expect do
      command '/deploy acme-inc/api@pending to production', as: slack_accounts(:david)
    end.to_not change { deployment_requests }

    callback_id = command_response.message.attachments[0].callback_id
    expect(command_response.message).to eq Slack::Message.new(text: <<-TEXT.strip_heredoc.strip, attachments: [Slack::Attachment.new(title: 'Ignore status checks and deploy anyway?', callback_id: callback_id, color: '#3AA3E3', actions: SlackMessage.confirmation_actions)])
    The following commit status checks are not passing:
    * *ci* [pending]
    TEXT

    expect do
      command '/deploy acme-inc/api@failing to production!', as: slack_accounts(:david)
    end.to change { deployment_requests.count }.by(1)
  end

  scenario 'performing a deployment of a branch that has failing commit status contexts by action' do
    expect do
      command '/deploy acme-inc/api@failing to production', as: slack_accounts(:david)
    end.to_not change { deployment_requests }

    callback_id = command_response.message.attachments[0].callback_id
    expect(command_response.message).to eq Slack::Message.new(text: <<-TEXT.strip_heredoc.strip, attachments: [Slack::Attachment.new(title: 'Ignore status checks and deploy anyway?', callback_id: callback_id, color: '#3AA3E3', actions: SlackMessage.confirmation_actions)])
    The following commit status checks are not passing:
    * *ci* [failure]
    TEXT

    expect do
      action 'yes', callback_id, as: slack_accounts(:david)
      callback_id = action_response.message.attachments[0].callback_id
      expect(action_response.message).to eq Slack::Message.new(
        text: 'Created deployment request for <https://github.com/acme-inc/api|acme-inc/api>@<https://github.com/acme-inc/api/commits/46c2acc4e588924340adcd108cfc948b|failing> to *production* (no change)',
        attachments: [
          Slack::Attachment.new(
            mrkdwn_in: ['text'],
            title: 'Lock production?',
            text: 'The default ref for *production* is `master`, but you deployed `failing`.',
            callback_id: callback_id,
            color: '#3AA3E3',
            actions: SlackMessage.confirmation_actions
          )
        ]
      )
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
    expect do
      command '/deploy acme-inc/api to staging', as: slack_accounts(:steve)
    end.to_not change { deployment_requests }

    callback_id = command_response.message.attachments[0].callback_id
    expect(command_response.message).to eq Slack::Message.new(text: '*staging* was locked by <@U012AB1AB> less than a minute ago.', attachments: [steal_lock_attachment(callback_id)])

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

    command '/deploy lock production on baxterthehacker/public-repo', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: "I don't know about any environments for baxterthehacker/public-repo. For details about configuring environments, see <https://slashdeploy.io/docs>.")

    command '/deploy unlock production on baxterthehacker/public-repo', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: "I don't know about any environments for baxterthehacker/public-repo. For details about configuring environments, see <https://slashdeploy.io/docs>.")
  end

  scenario 'checking a locked branch' do
    # It says that it's locked after someone locks it.
    command "/deploy lock staging on acme-inc/api: I'm testing some stuff", as: slack_accounts(:david)
    command '/deploy check staging on acme-inc/api', as: slack_accounts(:david)

    attachment = Slack::Attachment.new(mrkdwn_in: ['text'], color: '#F00', title: 'Lock Status', text: "*staging* was locked by <@U012AB1AB> less than a minute ago.\n> I'm testing some stuff")
    expect(command_response.message).to eq Slack::Message.new(text: 'acme-inc/api (*staging*)', attachments: [attachment])

    # It says it's unlocked after unlocking it.
    command '/deploy unlock staging on acme-inc/api', as: slack_accounts(:david)
    command '/deploy check staging on acme-inc/api', as: slack_accounts(:david)
    attachment = Slack::Attachment.new(mrkdwn_in: ['text'], color: '#3AA3E3', title: 'Lock Status', text: "*staging* isn't locked.")
    expect(command_response.message).to eq Slack::Message.new(text: 'acme-inc/api (*staging*)', attachments: [attachment])

    command '/deploy check production on baxterthehacker/public-repo', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: "I don't know about any environments for baxterthehacker/public-repo. For details about configuring environments, see <https://slashdeploy.io/docs>.")
  end

  scenario 'locking a branch with a message' do
    command "/deploy lock staging on acme-inc/api: I'm testing some stuff", as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Locked *staging* on acme-inc/api')

    # Other users shouldn't be able to deploy now.
    expect do
      command '/deploy acme-inc/api to staging', as: slack_accounts(:steve)
    end.to_not change { deployment_requests }

    callback_id = command_response.message.attachments[0].callback_id
    expect(command_response.message).to eq Slack::Message.new(text: "*staging* was locked by <@U012AB1AB> less than a minute ago.\n> I'm testing some stuff", attachments: [steal_lock_attachment(callback_id)])
  end

  scenario 'stealing a lock' do
    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Locked *staging* on acme-inc/api')

    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: '*staging* is already locked')

    expect do
      command '/deploy lock staging on acme-inc/api', as: slack_accounts(:steve)
    end.to_not change { deployment_requests }

    callback_id = command_response.message.attachments[0].callback_id
    expect(command_response.message).to eq Slack::Message.new(text: '*staging* was locked by <@U012AB1AB> less than a minute ago.', attachments: [steal_lock_attachment(callback_id)])

    command '/deploy lock staging on acme-inc/api!', as: slack_accounts(:steve)
    expect(command_response.message).to eq Slack::Message.new(text: 'Locked *staging* on acme-inc/api (stolen from <@U012AB1AB>)')

    expect do
      command '/deploy acme-inc/api to staging', as: slack_accounts(:david)
    end.to_not change { deployment_requests }
  end

  scenario 'trying to do something on a repo I dont have access to' do
    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:bob)
    expect(command_response.message).to eq Slack::Message.new(text: "Sorry, but it looks like you don't have access to acme-inc/api")
  end

  scenario 'finding the environments I can deploy a repo to' do
    command '/deploy where baxterthehacker/public-repo', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: "I don't know about any environments for baxterthehacker/public-repo. For details about configuring environments, see <https://slashdeploy.io/docs>.")

    repo = Repository.with_name("baxterthehacker/public-repo")
    repo.configure! nil
    command '/deploy where baxterthehacker/public-repo', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: "I don't know about any environments for baxterthehacker/public-repo. For details about configuring environments, see <https://slashdeploy.io/docs>.")

    repo = Repository.with_name("baxterthehacker/public-repo")
    repo.configure! <<-YAML.strip_heredoc
    environments:
      production: {}
    YAML

    command '/deploy where baxterthehacker/public-repo', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: <<-TEXT.strip_heredoc.strip)
    I know about these environments for baxterthehacker/public-repo:
    * production
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
      text: "I know about these environments for acme-inc/api:\n* production\n* staging\n* cd/no_contexts"
    )
  end

  scenario 'trying to /deploy an environment that is configured to auto deploy' do
    repo = Repository.with_name('acme-inc/api')
    repo.update_attributes! default_environment: 'cd/no_contexts'

    expect do
      command '/deploy acme-inc/api@master', as: slack_accounts(:david)
    end.to_not change { deployment_requests }

    callback_id = command_response.message.attachments[0].callback_id
    expect(command_response.message).to eq Slack::Message.new(text: 'acme-inc/api is configured to automatically deploy `refs/heads/master` to *cd/no_contexts*.', attachments: [
      Slack::Attachment.new(
        title: 'Deploy anyway?',
        callback_id: callback_id,
        color: '#3AA3E3',
        actions: SlackMessage.confirmation_actions
      )
    ])

    expect do
      command '/deploy acme-inc/api@master!', as: slack_accounts(:david)
    end.to change { deployment_requests.count }.by(1)
  end

  scenario 'trying to /deploy an environment that is configured to auto deploy by action' do
    repo = Repository.with_name('acme-inc/api')
    repo.update_attributes! default_environment: 'cd/no_contexts'

    expect do
      command '/deploy acme-inc/api@master', as: slack_accounts(:david)
    end.to_not change { deployment_requests }

    callback_id = command_response.message.attachments[0].callback_id
    expect(command_response.message).to eq Slack::Message.new(text: 'acme-inc/api is configured to automatically deploy `refs/heads/master` to *cd/no_contexts*.', attachments: [
      Slack::Attachment.new(
        title: 'Deploy anyway?',
        callback_id: callback_id,
        color: '#3AA3E3',
        actions: SlackMessage.confirmation_actions
      )
    ])

    expect do
      action 'yes', callback_id, as: slack_accounts(:steve)
      expect(action_response.message).to eq Slack::Message.new(text: 'Created deployment request for <https://github.com/acme-inc/api|acme-inc/api>@<https://github.com/acme-inc/api/commits/ad80a1b3e1a94b98ce99b71a48f811f1|master> to *cd/no_contexts* (no change)')
    end.to change { deployment_requests.count }.by(1)
  end

  scenario 'trying to /deploy an environment that is configured to auto deploy by action but whose context checks are failing' do
    repo = Repository.with_name('acme-inc/api')
    repo.update_attributes! default_environment: 'cd/no_contexts'

    expect do
      command '/deploy acme-inc/api@failing', as: slack_accounts(:david)
    end.to_not change { deployment_requests }

    callback_id = command_response.message.attachments[0].callback_id

    # let the user know this repo / environment uses ci, ask if they want to skip_ci_check.
    expect(command_response.message).to eq Slack::Message.new(
      text: 'acme-inc/api is configured to automatically deploy `refs/heads/master` to *cd/no_contexts*.',
      attachments: [
        Slack::Attachment.new(
          title: 'Deploy anyway?',
          callback_id: callback_id,
          color: '#3AA3E3',
          actions: SlackMessage.confirmation_actions
        )
      ]
    )

    # have the user click yes, to continue deploying, skipping cd.
    # deployment_request.count should stay at 0 and not increase.
    expect do
      action 'yes', callback_id, as: slack_accounts(:steve)
      callback_id = action_response.message.attachments[0].callback_id
      # expect the deployent request to raise an exception because of failing context checks.
      # message the user asking if we should force the deployment anyways.
      expect(command_response.message).to eq Slack::Message.new(text: <<-TEXT.strip_heredoc.strip, attachments: [Slack::Attachment.new(title: 'Ignore status checks and deploy anyway?', callback_id: callback_id, color: '#3AA3E3', actions: SlackMessage.confirmation_actions)])
      The following commit status checks are not passing:
      * *ci* [failure]
      TEXT
    end.to change { deployment_requests.count }.by(0)

    # have the user click yes, again, to skip context checks and
    # deploy a bad commit into environment...
    # deployment_request.count should increase.
    expect do
      action 'yes', callback_id, as: slack_accounts(:steve)
      callback_id = action_response.message.attachments[0].callback_id
    end.to change { deployment_requests.count }.by(1)
  end

  scenario 'stealing a lock by action' do
    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: 'Locked *staging* on acme-inc/api')

    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:david)
    expect(command_response.message).to eq Slack::Message.new(text: '*staging* is already locked')

    command '/deploy lock staging on acme-inc/api', as: slack_accounts(:steve)

    callback_id = command_response.message.attachments[0].callback_id
    expect(command_response.message).to eq Slack::Message.new(text: '*staging* was locked by <@U012AB1AB> less than a minute ago.', attachments: [steal_lock_attachment(callback_id)])

    expect do
      command '/deploy acme-inc/api to staging', as: slack_accounts(:steve)
    end.to_not change { deployment_requests }

    expect do # Decline option was selected
      action 'no', callback_id, as: slack_accounts(:steve)
    end.to_not change { deployment_requests }
    expect(action_response.message).to eq Slack::Message.new(text: 'Did not steal lock.')

    action 'yes', callback_id, as: slack_accounts(:steve)
    expect(action_response.message).to eq Slack::Message.new(text: 'Locked *staging* on acme-inc/api (stolen from <@U012AB1AB>)')

    expect do
      command '/deploy acme-inc/api to staging', as: slack_accounts(:david)
    end.to_not change { deployment_requests }
  end

  scenario 'trying to use a callback_id that does not exist' do
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
    expect do
      action 'yes', 'b1b111b1-1111-1b1b-b1b1-111bbb111111', as: slack_accounts(:steve)
    end.to_not change { deployment_requests }
    expect(action_response.message).to eq Slack::Message.new(text: "Oops! We had a problem running your command, but we've been notified")
  end

  scenario 'github deployment does not start after 30 simulated secs and triggers watchdog' do
    # make sure our queue is clear before starting test.
    GithubDeploymentWatchdogWorker.clear

    # our deployment watchdog worker should start with an empty queue.
    expect(GithubDeploymentWatchdogWorker.jobs.size).to eq 0

    # simulate a slashdeploy invocation.
    command '/deploy acme-inc/api to production', as: slack_accounts(:david)

    expect(command_response).to be_in_channel
    expect(deployment_requests).to eq [
      [users(:david), DeploymentRequest.new(repository: 'acme-inc/api', ref: 'master', environment: 'production')]
    ]

    # our deployment watchdog worker should start with an empty queue.
    expect(GithubDeploymentWatchdogWorker.jobs.size).to eq 1

    # setup expectations of the worker notifying the user there was an issue.
    expect(slack).to receive(:direct_message).with(
      slack_accounts(:david),
      Slack::Message.new(text: ':sadparrot: <@U012AB1AB>, The Github Deployment <1> of acme-inc/api@<ad80a1b3e1a94b98ce99b71a48f811f1|master> to *production* did _not_ start. For more details, please read: https://slashdeploy.io/docs#error-1'),
      any_args
    )

    # simulate waiting 30 secs and drain worker early to trigger a
    GithubDeploymentWatchdogWorker.drain

    # our deployment watchdog worker should start with an empty queue.
    expect(GithubDeploymentWatchdogWorker.jobs.size).to eq 0
  end

  def deployment_requests
    github.requests
  end

  def github
    SlashDeploy.service.github
  end

  def slack
    SlashDeploy.service.slack
  end

  # rubocop:disable Style/MethodName
  def HEAD(repository, ref, sha)
    github.HEAD(repository, ref, sha)
  end

  def steal_lock_attachment(callback_id)
    Slack::Attachment.new(
      title: 'Steal the lock?',
      callback_id: callback_id,
      color: '#3AA3E3',
      actions: SlackMessage.confirmation_actions
    )
  end
end
