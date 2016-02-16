require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:warden) { double('warden') }

  before do
    request.env['warden'] = warden
  end

  describe 'POST #create' do
    context 'new user, no existing identity' do
      it 'creates a new identity and a new user' do
        request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
        expect(warden).to receive(:authenticated?).and_return(false)
        expect(warden).to receive(:set_user)
        expect do
          post :create, provider: 'github'
        end.to change { User.count }.by(1)
      end
    end

    context 'existing user, logging in' do
      it 'signs them in to their existing account' do
        user = User.create(github_accounts: [GithubAccount.create_with_omniauth(OmniAuth.config.mock_auth[:github])])
        request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
        expect(warden).to receive(:authenticated?).and_return(false)
        expect(warden).to receive(:set_user).with(user)
        expect do
          post :create, provider: 'github'
        end.to_not change { User.count }
      end
    end

    pending 'existing user, different provider'

    context 'logged in user, logging in with same provider' do
      it 'signs them in again' do
        user = User.create(github_accounts: [GithubAccount.create_with_omniauth(OmniAuth.config.mock_auth[:github])])
        request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
        expect(warden).to receive(:authenticated?).and_return(true)
        expect(warden).to receive(:user).and_return(user)
        expect do
          post :create, provider: 'github'
        end.to_not change { User.count }
      end
    end

    context 'logged in user, logging in with new provider' do
      it 'links the account' do
        user = User.create
        request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
        expect(warden).to receive(:authenticated?).and_return(true)
        expect(warden).to receive(:user).at_least(:once).and_return(user)
        expect do
          post :create, provider: 'github'
        end.to change { GithubAccount.count }.by(1)
      end
    end
  end
end
