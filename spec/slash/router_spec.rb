require 'spec_helper'

RSpec.describe Slash::Router do
  describe '#match' do
    it 'adds a route that matches the text against the regular expression' do
      help = double(Slash::Handler)
      lock = double(Slash::Handler)

      router = Slash::Router.new
      router.match Slash.match_regexp(/^help$/), help
      router.match Slash.match_regexp(/^lock (?<thing>\S+?)$/), lock

      expect(help).to receive(:call)
      router.call('cmd' => Slash::Command.from_params('text' => 'help'))

      expect(lock).to receive(:call).with(hash_including('params' => { 'thing' => 'foo' }))
      router.call('cmd' => Slash::Command.from_params('text' => 'lock foo'))
    end
  end
end
