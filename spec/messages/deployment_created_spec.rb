require 'rails_helper'

RSpec.describe DeploymentCreatedMessage do
  describe '#to_message' do
    it 'returns a Slack::Message' do
      deployment = Deployment.new \
        id: 1234,
        repository: 'ejholmes/acme-inc'
      m = described_class.new(deployment: deployment).to_message
      expect(m.text).to eq "Created deployment request for #{deployment} (no change)"
    end
  end
end
