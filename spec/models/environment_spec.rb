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

  describe '#default_ref' do
    context 'when the environment has a default ref provided' do
      it 'returns that value' do
        environment = Environment.new(default_ref: 'develop')
        expect(environment.default_ref).to eq 'develop'
      end
    end

    context 'when the environment does not have a default ref' do
      it 'returns the global default' do
        environment = Environment.new(default_ref: '')
        expect(environment.default_ref).to eq 'master'

        environment = Environment.new
        expect(environment.default_ref).to eq 'master'
      end
    end
  end

  describe '#match_name' do
    context 'when the repository has a config set' do
      it 'returns the correct value' do
        repo = Repository.with_name('acme-inc/api')
        repo.configure! <<-YAML
environments:
  production:
    aliases: [prod]
YAML

        environment = Environment.new(name: 'production', repository: repo)
        expect(environment.match_name?('production')).to eq true
        expect(environment.match_name?('prod')).to eq true
        expect(environment.match_name?('pro')).to eq false
      end
    end
  end
end
