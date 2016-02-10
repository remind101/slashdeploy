require 'rails_helper'

RSpec.describe GithubController, type: :controller do
  let(:warden) { double('warden') }

  before do
    request.env['warden'] = warden
  end

  describe 'GET #callback' do
    before do
      stub_request(:post, 'https://github.com/login/oauth/access_token')
        .with(body: { 'client_id' => '', 'client_secret' => '', 'code' => 'code', 'grant_type' => 'authorization_code' })
        .to_return(status: 200, body: { 'access_token' => 'e72e16c7e42f292c6912e7710c838347ae178b4a', 'scope' => 'repo_deployment', 'token_type' => 'bearer' }.to_json, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, 'https://api.github.com/user')
        .to_return(status: 200, body: { 'id' => 1, 'login' => 'david' }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    context 'with an invalid state param' do
      it 'raises an error' do
        # TODO: Render something?
        expect { get :callback, state: 'invalid', code: 'code' }.to raise_error JWT::DecodeError
      end
    end

    context 'when the slack account does not exist' do
      it 'creates a new user and authenticates them' do
        state = SlashDeploy.state.encode('user_id' => 'U01', 'user_name' => 'david', 'team_id' => '1234', 'team_domain' => 'acme')
        expect(warden).to receive(:set_user).with(kind_of(User))
        expect { get :callback, state: state, code: 'code' }.to change { User.count }
      end
    end

    context 'when the slack account does not exist but the github account does' do
      let(:user) { User.create! }

      before do
        user.github_accounts << GithubAccount.new(id: '1', login: 'david', token: 'abcd')
      end

      it 'links this slack account to the existing user' do
        state = SlashDeploy.state.encode('user_id' => 'U01', 'user_name' => 'david', 'team_id' => '1234', 'team_domain' => 'acme')
        expect(warden).to receive(:set_user).with(kind_of(User))
        expect { get :callback, state: state, code: 'code' }.to change { user.slack_accounts.count }.by(1)
      end
    end

    context 'when the slack account already exists' do
      before do
        user = User.create!
        user.slack_accounts << SlackAccount.new(id: 'U01', user_name: 'david', slack_team: SlackTeam.new(id: '1234', domain: 'acme'))
      end

      it 'logs the user in' do
        state = SlashDeploy.state.encode('user_id' => 'U01', 'user_name' => 'david', 'team_id' => '1234', 'team_domain' => 'acme')
        expect(warden).to receive(:set_user).with(kind_of(User))
        expect { get :callback, state: state, code: 'code' }.to_not change { User.count }
      end
    end
  end
end
