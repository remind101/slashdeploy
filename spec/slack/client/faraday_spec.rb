require 'rails_helper'

RSpec.describe Slack::Client::Faraday do
  let(:connection) { instance_double(Faraday::Connection) }
  let(:client) { described_class.new connection }

  describe '#direct_message' do
    let(:slack_account) { stub_model(SlackAccount, id: 'U123BC2BD', bot_access_token: 'access_token') }

    it 'posts a chat message' do
      expect(connection).to receive(:post).with(
        '/api/chat.postMessage',
        token: 'access_token',
        channel: 'U123BC2BD',
        text: 'Hello World'
      )
      client.direct_message(slack_account, 'Hello World')
    end
  end
end
