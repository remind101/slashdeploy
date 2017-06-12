require 'rails_helper'

RSpec.describe GitHub::App do
  let(:private_key) { OpenSSL::PKey::RSA.new(GITHUB_APP_PEM) }
  let(:app) { described_class.new(1234, private_key) }

  describe '#app_token' do
    it 'generates a jwt signed token' do
      app.app_token
    end
  end

  describe '#installation_token' do
    it 'generates an access token for the installation' do
      stub_request(:post, 'https://api.github.com/installations/4321/access_tokens').
        with(headers: { 'Accept'=>'application/vnd.github.machine-man-preview+json' }).                                                                             
        to_return(status: 200, body: { "token": "v1.1f699f1069f60xxx", "expires_at": "2016-07-11T22:14:10Z" }.to_json, headers: { 'Content-Type' => 'application/json' })
      expect(app.installation_token(4321)).to eq 'v1.1f699f1069f60xxx'
    end
  end
end
