require 'spec_helper'

RSpec.describe GitHub::Integration do
  let(:connection) do
    Faraday.new 'https://api.github.com' do |builder|
      builder.request :json
      builder.response :json
      builder.adapter Faraday.default_adapter
    end
  end
  let(:private_key) { OpenSSL::PKey::RSA.new(FAKE_PRIVATE_PEM) }
  let(:integration) { described_class.new connection, private_key, 42 }

  describe '#installation_token' do
    context 'when on behalf of the installation' do
      it 'requests a token' do
        stub_request(:post, "https://api.github.com/installations/816/access_tokens").
          with(headers: {'Accept'=>'application/vnd.github.machine-man-preview+json'}).
          to_return(status: 200, body: '{ "token": "v1.1f699f1069f60xxx", "expires_at": "2016-07-11T22:14:10Z", "on_behalf_of": null }', headers: { 'Content-Type' => 'application/json' })
        expect(integration.installation_token(816).token).to eq 'v1.1f699f1069f60xxx'
      end
    end

    context 'when on behalf of a user' do
      it 'requests a token' do
        stub_request(:post, "https://api.github.com/installations/816/access_tokens").
          with(headers: {'Accept'=>'application/vnd.github.machine-man-preview+json'}, body: '{"user_id":1}').
          to_return(status: 200, body: '{ "token": "v1.1f699f1069f60xxx", "expires_at": "2016-07-11T22:14:10Z", "on_behalf_of": null }', headers: { 'Content-Type' => 'application/json' })
        expect(integration.installation_token(816, on_behalf_of: 1).token).to eq 'v1.1f699f1069f60xxx'
      end
    end
  end
end
