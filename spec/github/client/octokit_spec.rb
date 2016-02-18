require 'rails_helper'

RSpec.describe GitHub::Client::Octokit do
  let(:octokit_client) { double(Octokit::Client) }
  let(:user) { stub_model(User, octokit_client: octokit_client) }
  let(:client) { described_class.new }

  describe '#authorized?' do
    context 'when the user has access to the deployments of the repo' do
      it 'returns true' do
        expect(octokit_client).to receive(:deployments).with('remind101/acme-inc', sha: '1')
        expect(client.access? user, 'remind101/acme-inc').to be_truthy
      end
    end

    context 'when the user does not have access to the deployments of the repo' do
      it 'returns false' do
        expect(octokit_client).to receive(:deployments).with('remind101/acme-inc', sha: '1').and_raise(
          Octokit::NotFound.new
        )
        expect(client.access? user, 'remind101/acme-inc').to be_falsey
      end
    end
  end
end
