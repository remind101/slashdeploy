require 'rails_helper'

RSpec.feature 'Add to Slack' do
  fixtures :all

  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
  end

  scenario 'clicking the Add to Slack button' do
    visit '/slack/install'
    expect(page).to have_content 'Success!'
  end
end
