require 'rails_helper'

RSpec.describe Deployment, type: :model do
  describe '#organization' do
    it 'returns the organization' do
      deployment = Deployment.new(url: 'https://api.github.com/repos/octocat/example/deployments/1')
      expect(deployment.organization).to eq 'octocat'
    end
  end
end
