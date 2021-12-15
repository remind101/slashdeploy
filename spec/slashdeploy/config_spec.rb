require 'rails_helper'

RSpec.describe SlashDeploy::Config do
  describe '#from_yaml' do
    it 'loads a config from yaml' do
      config = described_class.from_yaml <<-YAML
environments:
  staging:
    aliases:
    - stage
  production:
    aliases:
    - prod
    continuous_delivery:
      ref: ref/heads/master
YAML

      expect(config.environments.length).to eq 2
      expect(config.environments["staging"].aliases).to eq ["stage"]
      expect(config.environments["production"].continuous_delivery.ref).to eq "ref/heads/master"
    end
  end
end
