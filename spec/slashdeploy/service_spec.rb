require 'rails_helper'

RSpec.describe SlashDeploy::Service do
  fixtures :users

  let(:user) { users(:david) }
  let(:deployer) { double(SlashDeploy::Deployer) }
  let(:authorizer) { double(SlashDeploy::Authorizer, authorized?: true) }
  let(:service) do
    described_class.new.tap do |service|
      service.deployer   = deployer
      service.authorizer = authorizer
    end
  end

  describe '#create_deployment' do
    context 'when no environment or ref is provided' do
      it 'sets the default environment' do
        req = DeploymentRequest.new(
          repository: 'remind101/acme-inc',
          environment: 'production',
          ref: 'master'
        )
        expect(deployer).to receive(:create_deployment).with(user, req)

        service.create_deployment(user, DeploymentRequest.new(repository: 'remind101/acme-inc'))
      end
    end

    context 'when the environment is locked' do
      before do
        service.lock_environment(user, LockRequest.new(repository: 'remind101/acme-inc', environment: 'staging', message: 'Testing some stuff'))
      end

      it 'raises an exception' do
        expect do
          service.create_deployment(users(:steve), DeploymentRequest.new(repository: 'remind101/acme-inc', environment: 'staging'))
        end.to raise_exception SlashDeploy::EnvironmentLockedError
      end
    end
  end

  describe '#lock_environment' do
    context 'when the environment does not exist yet' do
      it 'creates the environment and locks it' do
        expect do
          service.lock_environment(user, LockRequest.new(repository: 'remind101/acme-inc', environment: 'staging', message: 'Testing some stuff'))
        end.to change { Lock.count }
      end
    end
  end

  describe '#unlock_environment' do
    context 'when the environment is locked' do
      let(:lock) { service.lock_environment(user, LockRequest.new(repository: 'remind101/acme-inc', environment: 'staging', message: 'Testing some stuff')).lock }

      it 'unlocks it' do
        expect do
          service.unlock_environment(user, UnlockRequest.new(repository: 'remind101/acme-inc', environment: 'staging'))
        end.to change { lock.reload.active }.from(true).to(false)
      end
    end
  end
end
