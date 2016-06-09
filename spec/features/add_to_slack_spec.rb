require 'rails_helper'

RSpec.feature 'Add to Slack' do
  fixtures :all

  scenario 'clicking the Add to Slack button' do
    stub_request(:post, 'https://slack.com/api/oauth.access')
      .with(body: { 'client_id' => '', 'client_secret' => '', 'code' => 'code', 'grant_type' => 'authorization_code' })
      .to_return(status: 200, body: {
        'access_token' => 'xoxt-23984754863-2348975623103',
        'scope' => 'read',
        'team_name' => 'Acme',
        'team_id' => 'XXXXXXXXXX',
        'bot' => {
          'bot_user_id' => 'UTTTTTTTTTTR',
          'bot_access_token' => 'xoxb-XXXXXXXXXXXX-TTTTTTTTTTTTTT'
        }
      }.to_json, headers: { 'Content-Type': 'application/json' })
    expect do
      visit '/auth/slack/callback?code=code'
    end.to change { SlackBot.count }.by(1)
    expect(page).to have_content 'Success!'
  end
end
