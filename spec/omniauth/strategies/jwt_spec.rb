require 'spec_helper'
require 'omniauth/strategies/jwt'

RSpec.describe OmniAuth::Strategies::JWT do
  include Rack::Test::Methods

  let(:secret) { 'abcd' }
  let(:backend) { -> (_env) { [200, {}, ['Hello World']] } }
  let(:app) { described_class.new backend, callback_path: '/auth/jwt/callback', secret: secret }

  before do
    allow(OmniAuth.config).to receive(:test_mode).and_return(false)
  end

  context 'callback phase' do
    before do
      env 'rack.session', ''
    end

    it 'raises an error when there is no JWT token' do
      get '/auth/jwt/callback'
      expect(last_request.env['omniauth.error']).to be_present
    end

    it 'raises an error when the JWT token is invalid' do
      get '/auth/jwt/callback', 'jwt': 'foo'
      expect(last_request.env['omniauth.error']).to be_present
    end

    it 'authenticates succesfully when the JWT token is valid' do
      claims = {
        id: 5,
        exp: 1.minutes.from_now.to_i,
        iat: Time.now.to_i
      }
      get '/auth/jwt/callback', 'jwt': JWT.encode(claims, secret)
      expect(last_request.env['omniauth.auth'].uid).to eq 5
    end
  end
end
