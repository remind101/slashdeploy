require 'spec_helper'

RSpec.describe Hookshot do
  describe '.signature' do
    it 'calculates the signature' do
      signature = Hookshot.signature '{"event":"data"}', '1234'
      expect(signature).to eq 'ade133892a181fba3a21c163cd5cbc3f5f8e915c'
    end
  end
end
