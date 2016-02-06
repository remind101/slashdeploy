require 'rails_helper'

RSpec.feature 'Add to Slack' do
  fixtures :all
  include Rack::Test::Methods
  let(:app) { SlashDeploy.app }

  scenario 'clicking the Add to Slack button' do
    stub_request(:post, 'https://slack.com/api/oauth.access')
      .with(body: { 'client_id' => '', 'client_secret' => '', 'code' => 'code', 'grant_type' => 'authorization_code'})
      .to_return(status: 200, body: { 'access_token' => 'xoxt-23984754863-2348975623103', 'scope' => 'read' }.to_json, headers: { 'Content-Type': 'application/json' })
    visit '/auth/slack/callback?code=code'
    expect(page).to have_content 'Success!'
  end
end
