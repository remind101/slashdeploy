require 'rails_helper'

RSpec.describe GitHubEventHandler do
  let(:handler) do
    Class.new(GitHubEventHandler) do
      def run
      end
    end
  end

  describe '#call' do
    context 'when the repo is not found' do
      # This should never actually happen. If it does, it means something is
      # misconfigured.
      it 'raises an error' do
        req = Rack::MockRequest.new(handler)
        expect do
          req.post \
            '/',
            input: {
              repository: {
                full_name: 'acme-inc/api'
              }
            }.to_json,
            'CONTENT_TYPE' => 'application/json'
        end.to raise_error GitHubEventHandler::UnknownRepository
      end
    end

    context 'when the signature does not match' do
      it 'returns a 403' do
        Repository.create!(name: 'acme-inc/api', github_secret: 'secret')
        req = Rack::MockRequest.new(handler)
        resp = req.post \
          '/',
          input: {
            repository: {
              full_name: 'acme-inc/api'
            }
          }.to_json,
          'CONTENT_TYPE' => 'application/json',
          'HTTP_X_HUB_SIGNATURE' => 'sha1=abcd'
        expect(resp.status).to eq 403
      end
    end

    context 'when the signature matches' do
      it 'returns a 200 and calls the handler' do
        Repository.create!(name: 'acme-inc/api', github_secret: 'secret')
        req = Rack::MockRequest.new(handler)
        resp = req.post \
          '/',
          input: {
            repository: {
              full_name: 'acme-inc/api'
            }
          }.to_json,
          'CONTENT_TYPE' => 'application/json',
          'HTTP_X_HUB_SIGNATURE' => 'sha1=a6a982a7d5a5925ba8cd5a5bc8826ffb84947ed3'
        expect(resp.status).to eq 200
      end
    end
  end
end
