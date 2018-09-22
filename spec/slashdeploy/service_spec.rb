require 'rails_helper'

RSpec.describe SlashDeploy::Service do
  fixtures :users
  fixtures :slack_accounts

  let(:github) { instance_double(GitHub::Client, access?: true) }
  let(:slack) { instance_double(Slack::Client) }
  let(:service) do
    described_class.new.tap do |service|
      service.github = github
      service.slack = slack
    end
  end

  describe '#create_deployment' do
    context 'when no environment or ref is provided' do
      it 'sets the default environment' do
        github_deployment = stub_model(
          Deployment,
          id: 1,
          url: 'https://api.gthub.com/repos/acme-inc/api/deployments/1',
          ref: 'master',
          environment: 'production',
          sha: '52bea69fa54a0ad7a4bdb305380ef43a'
        )
        repo = stub_model(Repository, name: 'acme-inc/api')
        env  = stub_model(Environment, repository: repo, name: 'production', active_lock: nil)
        expect(github).to receive(:access?).with(users(:david), 'acme-inc/api').and_return(true)
        expect(github).to receive(:last_deployment).with(users(:david), 'acme-inc/api', 'production').and_return(nil)
        expect(github).to receive(:create_deployment).with(
          users(:david),
          DeploymentRequest.new(
            repository: 'acme-inc/api',
            environment: 'production',
            ref: 'master'
          )
        ).and_return(github_deployment)
        resp = service.create_deployment(users(:david), env, 'master')
        expect(resp).to be_a(DeploymentResponse)
      end
    end

    context 'when the environment is locked' do
      it 'raises an exception' do
        repo = stub_model(Repository, name: 'acme-inc/api')
        lock = stub_model(Lock, user: users(:david))
        env  = stub_model(Environment, repository: repo, name: 'production', active_lock: lock)
        expect do
          service.create_deployment(users(:steve), env, 'master')
        end.to raise_exception SlashDeploy::EnvironmentLockedError
      end
    end
  end

  describe '#lock_environment' do
    context 'when there is no existing lock' do
      it 'locks the environment' do
        repo = stub_model(Repository, name: 'acme-inc/api')
        env  = stub_model(Environment, repository: repo, name: 'staging', active_lock: nil)
        expect(github).to receive(:access?).with(users(:david), 'acme-inc/api').and_return(true)
        expect(env).to receive(:lock!).with(users(:david), 'Testing some stuff')
        service.lock_environment(users(:david), env, message: 'Testing some stuff')
      end
    end

    context 'when there is an existing lock held by a different user' do
      it 'locks the environment' do
        repo = stub_model(Repository, name: 'acme-inc/api')
        lock = stub_model(Lock, user: users(:steve))
        env  = stub_model(Environment, repository: repo, name: 'staging', active_lock: lock)
        expect(github).to receive(:access?).with(users(:david), 'acme-inc/api').and_return(true)
        expect(env).to_not receive(:lock!).with(users(:david), 'Testing some stuff')
        expect do
          service.lock_environment(users(:david), env, message: 'Testing some stuff')
        end.to raise_error SlashDeploy::EnvironmentLockedError
      end
    end

    context 'when there is an existing lock held by the same user' do
      it 'returns nil' do
        repo = stub_model(Repository, name: 'acme-inc/api')
        lock = stub_model(Lock, user: users(:david))
        env  = stub_model(Environment, repository: repo, name: 'staging', active_lock: lock)
        expect(github).to receive(:access?).with(users(:david), 'acme-inc/api').and_return(true)
        resp = service.lock_environment(users(:david), env, message: 'Testing some stuff')
        expect(resp).to be_nil
      end
    end
  end

  describe '#unlock_environment' do
    context 'when the environment has an active_lock by user' do
      it 'unlocks it' do
        repo = stub_model(Repository, name: 'acme-inc/api')
        lock = stub_model(Lock, user: users(:david))
        env  = stub_model(Environment, repository: repo, name: 'staging', active_lock: lock)
        expect(github).to receive(:access?).with(users(:david), 'acme-inc/api').and_return(true)
        expect(env.active_lock).to receive(:unlock!)
        service.unlock_environment(users(:david), env)
      end
    end
  end

  describe '#unlock_all' do
    context 'when the user has multiple locks' do
      it 'unlocks each' do
        repo = stub_model(Repository, name: 'acme-inc/api')
        lock1 = stub_model(Lock, user: users(:david), active: true)
        lock2 = stub_model(Lock, user: users(:david), active: true)
        env1  = stub_model(Environment, repository: repo, name: 'staging', active_lock: lock1)
        env2  = stub_model(Environment, repository: repo, name: 'production', active_lock: lock2)
        expect(users(:david)).to receive(:unlock_all!)
        service.unlock_all(users(:david))
      end
    end
  end

  describe '#create_message_action' do
    it 'generates a uuid' do
      action = service.create_message_action(BaseAction)
      expect(action.callback_id).not_to be_empty
    end
  end
end
