require 'spec_helper'

RSpec.describe Slash::Response do
  describe '#to_json' do
    it 'returns a suitable json response for an incoming webhook' do
      message = Slack::Message.new(text: 'Hello World')

      response = Slash::Response.new(message: message)
      expect(response.to_json).to eq '{"text":"Hello World","attachments":[]}'

      response = Slash::Response.new(message: message, in_channel: true)
      expect(response.to_json).to eq '{"text":"Hello World","attachments":[],"response_type":"in_channel"}'
    end
  end
end
