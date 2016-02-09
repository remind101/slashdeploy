require 'rails_helper'

RSpec.describe Environment, type: :model do
  describe '#in_channel' do
    it 'defaults to true for production environments' do
      environment = Environment.new(name: 'production')
      expect(environment.in_channel).to be_truthy
    end

    it 'defaults to false for other environments' do
      environment = Environment.new(name: 'staging')
      expect(environment.in_channel).to be_falsy
    end
  end
end
