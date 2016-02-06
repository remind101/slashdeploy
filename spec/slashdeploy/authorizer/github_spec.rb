require 'rails_helper'

RSpec.describe SlashDeploy::Authorizer::GitHub do
  let(:client) { double(Octokit::Client) }
  let(:user) { stub_model(User, github_client: client) }
  let(:authorizer) { described_class.new }

  describe '#authorized?' do
    context 'when the user has access to the deployments of the repo' do
      it 'returns true' do
        expect(client).to receive(:deployments).with('remind101/acme-inc', sha: '1')
        expect(authorizer.authorized? user, 'remind101/acme-inc').to be_truthy
      end
    end

    context 'when the user does not have access to the deployments of the repo' do
      it 'returns false' do
        expect(client).to receive(:deployments).with('remind101/acme-inc', sha: '1').and_raise(
          Octokit::NotFound.new
        )
        expect(authorizer.authorized? user, 'remind101/acme-inc').to be_falsey
      end
    end
  end
end
