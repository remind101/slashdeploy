require 'rails_helper'

RSpec.describe SlashDeploy::Service do
  let(:deployer) { double('Deployer') }
  let(:service) do
    described_class.new.tap do |service|
      service.deployer = -> (_user) { deployer }
    end
  end

  describe '#create_deployment' do
    context 'when no environment or ref is provided' do
      it 'sets the default environment' do
        user = mock_model(User)

        req = DeploymentRequest.new(
          repository: 'remind101/acme-inc',
          environment: 'production',
          ref: 'master'
        )
        expect(deployer).to receive(:create_deployment).with(req)

        service.create_deployment(user, DeploymentRequest.new(repository: 'remind101/acme-inc'))
      end
    end
  end
end
