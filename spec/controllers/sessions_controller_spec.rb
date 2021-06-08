require 'rails_helper'

# Solve rake failures post-upgrade to Ruby 2.6.x per https://github.com/rails/rails/issues/34790#issuecomment-450502805more 
if RUBY_VERSION>='2.6.0'
  if Rails.version < '5'
    class ActionController::TestResponse < ActionDispatch::TestResponse
      def recycle!
        # hack to avoid MonitorMixin double-initialize error:
        @mon_mutex_owner_object_id = nil
        @mon_mutex = nil
        initialize
      end
    end
  else
    puts "Monkeypatch for ActionController::TestResponse no longer needed"
  end
end


RSpec.describe SessionsController, type: :controller do
  fixtures :users, :github_accounts

  let(:warden) { MockWarden.new }

  before do
    request.env['warden'] = warden
  end

  describe 'POST #destroy' do
    it 'logs the user out' do
      expect(warden).to receive(:logout)
      post :destroy
    end
  end

  describe 'GET #create (GitHub)' do
    context 'when the user is signed in' do
      before do
        warden.set_user users(:david)
      end

      context 'and the account already belongs to the authenticated user' do
        before do
          request.env['omniauth.auth'] = OmniAuth::AuthHash.new(
            provider: 'github',
            uid: github_accounts(:david),
            info: {
              nickname: 'david'
            },
            credentials: {
              token: 'abcd'
            }
          )
        end

        it "let's the user know that they've already added the account" do
          expect(warden).to_not receive(:set_user)
          expect do
            get :create, provider: 'github'
          end.to_not change { [GitHubAccount.count, github_accounts(:david).user] }
        end
      end

      context "and the account doesn't belong to the user" do
        before do
          request.env['omniauth.auth'] = OmniAuth::AuthHash.new(
            provider: 'github',
            uid: '123545',
            info: {
              nickname: 'david2'
            },
            credentials: {
              token: 'abcd'
            }
          )
        end

        it 'links the account' do
          expect(warden).to_not receive(:set_user)
          expect do
            get :create, provider: 'github'
          end.to change { GitHubAccount.count }.by(1)
          expect(warden.user).to eq users(:david)
        end
      end
    end

    context 'when the user is not signed in' do
      context 'and the account belongs to an existing user' do
        before do
          request.env['omniauth.auth'] = OmniAuth::AuthHash.new(
            provider: 'github',
            uid: github_accounts(:david).id,
            info: {
              nickname: 'david'
            },
            credentials: {
              token: 'abcd'
            }
          )
        end

        it 'signs the user in' do
          expect do
            get :create, provider: 'github'
          end.to_not change { User.count }
          expect(warden.user).to eq users(:david)
        end
      end

      context 'and the account does not belong to an existing user' do
        before do
          request.env['omniauth.auth'] = OmniAuth::AuthHash.new(
            provider: 'github',
            uid: '123545',
            info: {
              nickname: 'ejholmes'
            },
            credentials: {
              token: 'abcd'
            }
          )
        end

        it 'creates a new user, links the account, and signs them in' do
          expect do
            get :create, provider: 'github'
          end.to change { User.count }.by(1)

          expect(warden.user).to be_persisted
          expect(warden.user.github_accounts.count).to eq 1
        end
      end
    end
  end
end
