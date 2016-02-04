require 'rails_helper'

RSpec.describe SlashDeploy::Deployer::GitHub do
  let(:client) { double('GitHub Client') }
  let(:deployer) { described_class.new client }

  describe '#create_deployment' do
    it 'creates the github deployment' do
      req = DeploymentRequest.new(
        repository: 'remind101/acme-inc',
        ref: 'master',
        environment: 'production'
      )

      expect(client).to receive(:create_deployment).with(
        'remind101/acme-inc',
        'master',
        environment: 'production',
        task: 'deploy',
        auto_merge: false
      ).and_return(double('GitHub Deployment', id: 1))

      id = deployer.create_deployment req
      expect(id).to eq 1
    end

    context 'when the commit has failing commit statuses' do
      it 'raises an exception' do
        req = DeploymentRequest.new(
          repository: 'remind101/acme-inc',
          ref: 'master',
          environment: 'production'
        )

        conflict = Octokit::Conflict.new(
          method: 'POST',
          status: 409,
          body: {
            errors: {
              contexts: [
                { context: 'ci/circleci', state: 'success' },
                { context: 'container/docker', state: 'failure' }
              ],
              resource: 'Deployment',
              field: 'required_contexts',
              code: 'invalid'
            }
          }
        )
        expect(client).to receive(:create_deployment).and_raise(conflict)
        expect do
          begin
            deployer.create_deployment req
          rescue SlashDeploy::RedCommitError => e
            expect(e.contexts).to eq [
              CommitStatusContext.new(context: 'ci/circleci', state: 'success'),
              CommitStatusContext.new(context: 'container/docker', state: 'failure')
            ]
            raise
          end
        end.to raise_error SlashDeploy::RedCommitError
      end
    end
  end
end
