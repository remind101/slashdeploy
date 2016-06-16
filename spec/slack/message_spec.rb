require 'spec_helper'

RSpec.describe Slack::Message do
  it 'builds messages' do
    m = Slack::Message.new
    m.text = 'Hello World'
    m.attachments = [
      Slack::Attachment.new(
        text: 'Some attachment'
      )
    ]
  end
end
