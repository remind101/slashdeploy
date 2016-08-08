require 'rails_helper'

RSpec.describe SlashDeploy::Auth do
  let(:handler) { instance_double(Slash::Handler) }
  let(:oauth_client) do
    OAuth2::Client.new(
      'client_id',
      'client_secret',
      site: 'https://api.github.com',
      authorize_url: 'https://github.com/login/oauth/authorize',
      token_url: 'https://github.com/login/oauth/access_token'
    )
  end
  let(:state_encoder) { SlashDeploy::State.new 'secret' }
  let(:middleware) { described_class.new handler, oauth_client, state_encoder }

  describe 'call' do
    context 'when the user cannot be found' do
      before do
        allow(User).to receive(:find_by_id).and_return(nil)
      end

      it 'responds by asking the user to authenticate' do
        stub_request(:post, 'http://localhost/')
          .with(body: { 'text' => "I don't know who you are on GitHub yet. Please <https://github.com/login/oauth/authorize?client_id=client_id&response_type=code&scope=repo_deployment&state=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjpudWxsfQ.3zmU33IdlkHORNs7CcCob6kOme-TI-GY_delFRofJ6g|authenticate> then try again." }.to_json)
        middleware.call('cmd' => Slash::Command.new(Slash::CommandPayload.new response_url: 'http://localhost/'))
      end
    end
  end
end
