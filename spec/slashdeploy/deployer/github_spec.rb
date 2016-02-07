require 'rails_helper'

RSpec.describe SlashDeploy::Deployer::GitHub do
  let(:client) { double(Octokit::Client) }
  let(:user) { stub_model(User, github_client: client) }
  let(:deployer) { described_class.new }

  describe '#create_deployment' do
    context 'when there are no previous deployments to the environment' do
      it 'creates the github deployment' do
        req = DeploymentRequest.new(
          repository: 'remind101/acme-inc',
          ref: 'master',
          environment: 'production'
        )

        github_deployment = double(
          'GitHub Deployment',
          id: 1,
          ref: 'master',
          environment: 'production',
          sha: '52bea69fa54a0ad7a4bdb305380ef43a'
        )
        expect(client).to receive(:create_deployment).with(
          'remind101/acme-inc',
          'master',
          environment: 'production',
          task: 'deploy',
          auto_merge: false
        ).and_return(github_deployment)
        expect(client).to receive(:deployments).with(
          'remind101/acme-inc',
          environment: 'production'
        ).and_return([])

        resp = deployer.create_deployment user, req
        expect(resp.deployment.id).to eq 1
        expect(resp.last_deployment).to be_nil
      end
    end

    context 'when there are previous deployments to the environment' do
      it 'creates the github deployment' do
        req = DeploymentRequest.new(
          repository: 'remind101/acme-inc',
          ref: 'master',
          environment: 'production'
        )

        last_github_deployment = double(
          'GitHub Deployment',
          id: 1,
          ref: 'master',
          environment: 'production',
          sha: 'ef892c97230add9a1250ec7e1d71b362'
        )
        github_deployment = double(
          'GitHub Deployment',
          id: 2,
          ref: 'master',
          environment: 'production',
          sha: '52bea69fa54a0ad7a4bdb305380ef43a'
        )
        expect(client).to receive(:create_deployment).with(
          'remind101/acme-inc',
          'master',
          environment: 'production',
          task: 'deploy',
          auto_merge: false
        ).and_return(github_deployment)
        expect(client).to receive(:deployments).with(
          'remind101/acme-inc',
          environment: 'production'
        ).and_return([last_github_deployment])

        resp = deployer.create_deployment user, req
        expect(resp.deployment.id).to eq 2
        expect(resp.last_deployment.id).to eq 1
      end
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
            errors: [{
              contexts: [
                { context: 'ci/circleci', state: 'success' },
                { context: 'container/docker', state: 'failure' }
              ],
              resource: 'Deployment',
              field: 'required_contexts',
              code: 'invalid'
            }]
          }
        )
        allow(client).to receive(:deployments).and_return([])
        expect(client).to receive(:create_deployment).and_raise(conflict)
        expect do
          begin
            deployer.create_deployment user, req
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
