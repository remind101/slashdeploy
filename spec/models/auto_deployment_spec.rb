require 'rails_helper'

RSpec.describe AutoDeployment, type: :model do
  describe '#state' do
    context 'when the deployment is inactive' do
      it 'returns :inactive' do
        auto_deployment = stub_model(AutoDeployment, active: false)
        expect(auto_deployment.state).to equal AutoDeployment::STATE_INACTIVE
      end
    end

    context 'when the environment does not have any required contexts' do
      it 'returns :ready' do
        environment = stub_model(Environment, required_contexts: nil)
        auto_deployment = stub_model(AutoDeployment, environment: environment)
        expect(auto_deployment.state).to equal AutoDeployment::STATE_READY

        environment = stub_model(Environment, required_contexts: [])
        auto_deployment = stub_model(AutoDeployment, environment: environment)
        expect(auto_deployment.state).to equal AutoDeployment::STATE_READY
      end
    end

    context 'when all required contexts are in a success state' do
      it 'returns :ready' do
        environment = Repository.with_name('acme-inc/api').environment('production')
        environment.update_attributes! required_contexts: ['ci/circleci', 'security/brakeman']
        Status.create! sha: 'abcd', context: 'ci/circleci', state: 'success'
        Status.create! sha: 'abcd', context: 'security/brakeman', state: 'success'
        auto_deployment = environment.auto_deployments.new sha: 'abcd'
        expect(auto_deployment.state).to equal AutoDeployment::STATE_READY
      end
    end

    context 'when only some of the required contexts are in a success state' do
      it 'returns :pending' do
        environment = Repository.with_name('acme-inc/api').environment('production')
        environment.update_attributes! required_contexts: ['ci/circleci', 'security/brakeman']
        ci = Status.create! sha: 'abcd', context: 'ci/circleci', state: 'success'
        auto_deployment = environment.auto_deployments.new sha: 'abcd'
        expect(auto_deployment.state).to equal AutoDeployment::STATE_PENDING

        expect(auto_deployment.required_statuses.length).to eq 2
        expect(auto_deployment.required_statuses[0]).to eq ci
        expect(auto_deployment.required_statuses[1].context).to eq 'security/brakeman'
        expect(auto_deployment.required_statuses[1].state).to eq CommitStatusContext::PENDING
      end
    end

    context 'when some of the required contexts are in a failing state' do
      it 'returns :pending' do
        environment = Repository.with_name('acme-inc/api').environment('production')
        environment.update_attributes! required_contexts: ['ci/circleci', 'security/brakeman']
        Status.create! sha: 'abcd', context: 'ci/circleci', state: 'success'
        Status.create! sha: 'abcd', context: 'ci/circleci', state: 'failure'
        auto_deployment = environment.auto_deployments.new sha: 'abcd'
        expect(auto_deployment.state).to equal AutoDeployment::STATE_PENDING
      end
    end

    context 'when all of the required contexts are tracked, but some are not successful' do
      it 'returns :failed' do
        environment = Repository.with_name('acme-inc/api').environment('production')
        environment.update_attributes! required_contexts: ['ci/circleci', 'security/brakeman']
        Status.create! sha: 'abcd', context: 'ci/circleci', state: 'failure'
        Status.create! sha: 'abcd', context: 'security/brakeman', state: 'success'
        auto_deployment = environment.auto_deployments.new sha: 'abcd'
        expect(auto_deployment.state).to equal AutoDeployment::STATE_FAILED
      end
    end
  end
end
