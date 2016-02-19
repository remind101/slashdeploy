require 'rails_helper'

RSpec.describe 'GitHub Webhooks' do
  describe 'ping' do
    it 'returns 200' do
      github_event :ping, ''
      expect(last_response.status).to eq 204
    end
  end
end
