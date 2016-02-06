require 'rails_helper'

RSpec.describe SlashDeploy::Authorizer::GitHub do
  let(:client) { double(Octokit::Client) }
  let(:user) { stub_model(User, github_client: client) }
  let(:authorizer) { described_class.new }

  describe '#authorized?' do
    context 'when the user is a collaborator on the repo' do
      it 'returns true' do
        expect(client).to receive(:collaborator?).and_return(true)
        expect(authorizer.authorized? user, 'remind101/acme-inc').to be_truthy
      end
    end

    context 'when the user is not a collaborator on the repo' do
      it 'returns false' do
        expect(client).to receive(:collaborator?).and_return(false)
        expect(authorizer.authorized? user, 'remind101/acme-inc').to be_falsey
      end
    end
  end
end
