require 'rails_helper'

RSpec.describe AutoDeployment, type: :model do
  describe '#ready?' do
    context 'when the environment does not have any required contexts' do
      it 'returns true' do
        environment = stub_model(Environment, required_contexts: nil)
        auto_deployment = stub_model(AutoDeployment, environment: environment)
        expect(auto_deployment).to be_ready

        environment = stub_model(Environment, required_contexts: [])
        auto_deployment = stub_model(AutoDeployment, environment: environment)
        expect(auto_deployment).to be_ready
      end
    end

    context 'when all required contexts are in a success state' do
      it 'returns true' do
        environment = Repository.with_name('remind101/acme-inc').environment('production')
        environment.update_attributes! required_contexts: ['ci/circleci', 'security/brakeman']
        Status.create! sha: 'abcd', context: 'ci/circleci', state: 'success'
        Status.create! sha: 'abcd', context: 'security/brakeman', state: 'success'
        auto_deployment = environment.auto_deployments.new sha: 'abcd'
        expect(auto_deployment).to be_ready
      end
    end

    context 'when only some of the required contexts are in a success state' do
      it 'returns false' do
        environment = Repository.with_name('remind101/acme-inc').environment('production')
        environment.update_attributes! required_contexts: ['ci/circleci', 'security/brakeman']
        Status.create! sha: 'abcd', context: 'ci/circleci', state: 'success'
        auto_deployment = environment.auto_deployments.new sha: 'abcd'
        expect(auto_deployment).to_not be_ready
      end
    end

    context 'when some of the required contexts are in a failing state' do
      it 'returns false' do
        environment = Repository.with_name('remind101/acme-inc').environment('production')
        environment.update_attributes! required_contexts: ['ci/circleci', 'security/brakeman']
        Status.create! sha: 'abcd', context: 'ci/circleci', state: 'success'
        Status.create! sha: 'abcd', context: 'ci/circleci', state: 'failure'
        auto_deployment = environment.auto_deployments.new sha: 'abcd'
        expect(auto_deployment).to_not be_ready
      end
    end
  end
end
