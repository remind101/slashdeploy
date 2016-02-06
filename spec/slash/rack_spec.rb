require 'spec_helper'

RSpec.describe Slash::Rack do
  let(:handler) { double }
  let(:app) { described_class.new handler }

  describe '#call' do
    context 'when a response is returned from the handler' do
      it 'returns the json representation of the response' do
        env = Rack::MockRequest.env_for(
          '/',
          method:
          'POST',
          input: 'command=/deploy&text=thing&token=foo'
        )
        expect(handler).to receive(:call).with(
          'cmd' => Slash::Command.new(
            Slash::Request.new(
              command: '/deploy',
              text: 'thing',
              token: 'foo'
            )
          )
        ).and_return(Slash.say('Hello'))
        status, headers, body = app.call(env)
        expect(status).to eq 200
        expect(headers).to eq('Content-Type' => 'application/json')
        expect(body).to eq ["{\"text\":\"Hello\",\"response_type\":\"in_channel\"}"]
      end
    end

    context 'when a response is not returned from the handler' do
      it 'returns an empty response' do
        env = Rack::MockRequest.env_for('/')
        expect(handler).to receive(:call).and_return(nil)
        status, headers, body = app.call(env)
        expect(status).to eq 200
        expect(headers).to eq({})
        expect(body).to eq ['']
      end
    end

    context 'when the handler raises a Slash::UnverifiedError' do
      it 'returns a 403' do
        env = Rack::MockRequest.env_for('/')
        expect(handler).to receive(:call).and_raise(Slash::UnverifiedError)
        status, headers, body = app.call(env)
        expect(status).to eq 403
        expect(headers).to eq({})
        expect(body).to eq ['']
      end
    end
  end
end
