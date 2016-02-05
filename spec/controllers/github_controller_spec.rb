require 'rails_helper'

RSpec.describe GithubController do
  let(:warden) { double('warden') }

  before do
    request.env['warden'] = warden
  end

  describe 'GET #callback' do
    before do
      stub_request(:post, 'https://github.com/login/oauth/access_token')
        .with(body: { 'client_id' => '', 'client_secret' => '', 'code' => 'code', 'grant_type' => 'authorization_code' })
        .to_return(status: 200, body: { 'access_token' => 'e72e16c7e42f292c6912e7710c838347ae178b4a', 'scope' => 'repo_deployment', 'token_type' => 'bearer' }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    context 'with an invalid state param' do
      it 'raises an error' do
        # TODO: Render something?
        expect { get :callback, state: 'invalid', code: 'code' }.to raise_error JWT::DecodeError
      end
    end

    context 'when the user does not exist' do
      before do
        stub_request(:get, 'https://api.github.com/user')
          .to_return(status: 200, body: { 'id' => 1, 'login' => 'david' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'creates a new user and authenticates them' do
        state = SlashDeploy.state.encode('user_id' => '1', 'user_name' => 'david')
        expect(warden).to receive(:set_user).with(kind_of(User))
        expect { get :callback, state: state, code: 'code' }.to change { User.count }
      end
    end

    context 'when the user already exists' do
      before do
        user = User.create!
        user.connected_accounts << SlackAccount.new(foreign_id: 'U01')
      end

      it 'logs the user in' do
        state = SlashDeploy.state.encode('user_id' => 'U01')
        expect(warden).to receive(:set_user).with(kind_of(User))
        expect { get :callback, state: state, code: 'code' }.to_not change { User.count }
      end
    end
  end
end
