require 'spec_helper'

RSpec.describe Slash::Middleware::Verify do
  let(:handler) { double('Slash::Handler') }

  describe '#call' do
    context 'when the token matches' do
      it 'calls the handler' do
        h = described_class.new handler, 'secret'
        env = { 'cmd' => Slash::Command.from_params('token' => 'secret') }

        expect(handler).to receive(:call).with(env)
        h.call(env)
      end
    end

    context 'when the token does not match' do
      it 'raises' do
        h = described_class.new handler, 'secret'
        env = { 'cmd' => Slash::Command.from_params('token' => 'l33thacks') }

        expect(handler).to_not receive(:call).with(env)
        expect { h.call(env) }.to raise_error Slash::UnverifiedError
      end
    end
  end
end
