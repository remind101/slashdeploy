require 'rails_helper'

RSpec.describe GitHubEventHandler do
  fixtures :installations

  let(:handler) do
    Class.new(GitHubEventHandler) do
      def run
      end
    end
  end

  describe '#call from installation' do
    context 'when the repo is not found' do
      # This could happen if the integration is installed organization wide.
      it 'verifies the signature and creates the repository' do
        req = Rack::MockRequest.new(handler)
        expect do
          resp = req.post \
            '/',
            input: {
              repository: {
                full_name: 'acme-inc/api'
              },
              installation: {
                id: 1234
              }
            }.to_json,
            'CONTENT_TYPE' => 'application/json',
            'HTTP_X_HUB_SIGNATURE' => 'sha1=1290d145b7ac29e87238b4b129bc10076e22387f'
          expect(resp.status).to eq 200
        end.to change { Repository.count }
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
            },
            installation: {
              id: 1234
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
            },
            installation: {
              id: 1234
            }
          }.to_json,
          'CONTENT_TYPE' => 'application/json',
          'HTTP_X_HUB_SIGNATURE' => 'sha1=1290d145b7ac29e87238b4b129bc10076e22387f'
        expect(resp.status).to eq 200
      end
    end
  end
end
