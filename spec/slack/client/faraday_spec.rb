require 'rails_helper'

RSpec.describe Slack::Client::Faraday do
  let(:client) { described_class.build }

  describe '#direct_message' do
    let(:slack_account) { stub_model(SlackAccount, id: 'U123BC2BD', bot_access_token: 'access_token') }

    describe 'when the message is properly formatted' do
      it 'posts a chat message' do
        stub_request(:post, 'https://slack.com/api/chat.postMessage')
          .with(body: { 'channel' => 'U123BC2BD', 'text' => 'Hello World', 'token' => 'access_token' })
          .to_return(status: 200, body: '{"ok":true}', headers: { 'Content-Type' => 'application/json' })
        message = Slack::Message.new text: 'Hello World'
        client.direct_message(slack_account, message)
      end
    end

    describe 'when the message has attachements' do
      it 'posts a chat message' do
        stub_request(:post, 'https://slack.com/api/chat.postMessage')
          .with(body: { 'attachments' => "[{\"mrkdwn_in\":[],\"text\":\"Hello World\",\"fallback\":null,\"callback_id\":null,\"color\":null,\"pretext\":null,\"author_name\":null,\"author_link\":null,\"author_icon\":null,\"title\":null,\"title_link\":null,\"fields\":[],\"actions\":[],\"image_url\":null,\"thumb_url\":null,\"footer\":null,\"footer_icon\":null,\"ts\":null}]", 'channel' => 'U123BC2BD', 'text' => '', 'token' => 'access_token' })
          .to_return(status: 200, body: '{"ok":true}', headers: { 'Content-Type' => 'application/json' })
        message = Slack::Message.new attachments: [Slack::Attachment.new(text: 'Hello World')]
        client.direct_message(slack_account, message)
      end
    end

    describe 'when the message is malformed' do
      it 'raises an error' do
        stub_request(:post, 'https://slack.com/api/chat.postMessage')
          .with(body: { 'channel' => 'U123BC2BD', 'text' => 'Hello World', 'token' => 'access_token' })
          .to_return(status: 200, body: '{"ok":false,"error":"invalid_array_arg"}', headers: { 'Content-Type' => 'application/json' })
        message = Slack::Message.new text: 'Hello World'
        expect do
          client.direct_message(slack_account, message)
        end.to raise_error Slack::Client::Error, 'invalid_array_arg'
      end
    end
  end
end
