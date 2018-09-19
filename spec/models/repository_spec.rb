require 'rails_helper'

RSpec.describe Repository, type: :model do

  describe '#name' do
    it 'gets validated as a GitHub repository name' do
      repo = Repository.new(name: 'foo')
      expect(repo).to be_invalid
      expect(repo.errors[:name]).to eq ['not a valid GitHub repository']
    end
  end

  describe '#organization' do
    it 'returns the organization' do
      repo = Repository.new(name: 'ejholmes/foo')
      expect(repo.organization).to eq 'ejholmes'
    end
  end

  describe '#environment' do
    context 'when given and environment name' do
      it 'returns the environment with that name' do
        repo = Repository.with_name('acme-inc/api')
        environment = repo.environment('staging')
        expect(environment).to_not be_nil
        expect(environment.name).to eq 'staging'
      end
    end
  end

  describe '#default_environment' do

    before do
      @repo = Repository.with_name('acme-inc/api')
      @repo.configure! <<-YAML
environments:
  production:
    aliases: [prod, default]
  stage:
    aliases: [staging]
YAML

      @env_prod = Environment.new(name: 'production', repository: @repo)
      @env_stage = Environment.new(name: 'stage', repository: @repo)
    end

    context 'when not given a name' do
      it 'returns the default environment' do
        environment = @repo.environment
        expect(environment).to_not be_nil
        expect(environment.name).to eq "production"
      end
    end

    context 'when the repository has a config set' do
      it 'returns the correct value' do

        expect(@env_prod.match_name?('production')).to eq true
        expect(@env_prod.match_name?('prod')).to eq true
        expect(@env_prod.match_name?('pro')).to eq false
        expect(@env_prod.is_default?).to eq true

        expect(@env_stage.match_name?('stage')).to eq true
        expect(@env_stage.match_name?('staging')).to eq true
        expect(@env_stage.match_name?('salsa')).to eq false
        expect(@env_stage.is_default?).to eq false

        expect(@repo.default_environment.name).to eq @env_prod.name
      end
    end
  end
end
