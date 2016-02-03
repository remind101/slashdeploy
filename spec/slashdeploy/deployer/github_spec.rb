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
  end
end
