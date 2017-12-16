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
        )
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

    context 'when there is an existing lock held by a different user, and the :force flag is set' do
      it 'locks the environment' do
        repo = stub_model(Repository, name: 'acme-inc/api')
        lock = stub_model(Lock, user: users(:steve))
        env  = stub_model(Environment, repository: repo, name: 'staging', active_lock: lock)
        expect(github).to receive(:access?).with(users(:david), 'acme-inc/api').and_return(true)
        expect(lock).to receive(:unlock!)
        expect(env).to receive(:lock!).with(users(:david), 'Testing some stuff')
        expect(service).to_not receive(:direct_message)
        resp = service.lock_environment(users(:david), env, message: 'Testing some stuff', force: true)
        expect(resp.stolen).to eq lock
      end

      it 'locks the environment and sends a direct message when there\'s an account in the env' do
        repo = stub_model(Repository, name: 'acme-inc/api')
        lock = stub_model(Lock, user: users(:steve))

        # set up the associated github account in the env
        account = instance_double(SlackAccount)
        expect(account).to receive(:github_organization).and_return('acme-inc')

        env = stub_model(Environment, repository: repo, name: 'staging', active_lock: lock)
        expect(env).to receive(:[]).with('account').and_return(account)

        expect(github).to receive(:access?).with(users(:david), 'acme-inc/api').and_return(true)
        expect(env).to receive(:lock!).with(users(:david), 'Testing some stuff')
        expect(slack).to receive(:direct_message).with(
          slack_accounts(:steve),
          Slack::Message.new(text: "Your lock for *staging* on acme-inc/api was stolen by <@#{slack_accounts(:david).id}>"))
        expect(lock).to receive(:unlock!)
        resp = service.lock_environment(users(:david), env, message: 'Testing some stuff', force: true)
        expect(resp.stolen).to eq lock
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
    context 'when the environment is locked by a different user' do
      it 'unlocks it' do
        repo = stub_model(Repository, name: 'acme-inc/api')
        env  = stub_model(Environment, repository: repo, name: 'staging', active_lock: nil)
        expect(github).to receive(:access?).with(users(:david), 'acme-inc/api').and_return(true)
        expect(env).to receive(:lock!).with(users(:david), 'Testing some stuff')
        service.lock_environment(users(:david), env, message: 'Testing some stuff')
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
