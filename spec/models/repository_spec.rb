require 'rails_helper'

RSpec.describe Repository, type: :model do
  describe '#name' do
    it 'gets validated as a GitHub repository name' do
      repo = Repository.new(name: 'foo')
      expect(repo).to be_invalid
      expect(repo.errors[:name]).to eq ['is not a valid GitHub repository']
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

    context 'when not given a name' do
      it 'returns the default environment' do
        repo = Repository.with_name('acme-inc/api')
        environment = repo.environment
        expect(environment).to_not be_nil
        expect(environment.name).to eq 'production'
      end
    end
  end

  describe '#default_environment' do
    context 'when the repository has a default environment provided' do
      it 'returns that value' do
        repo = Repository.new(default_environment: 'staging')
        expect(repo.default_environment).to eq 'staging'
      end
    end

    context 'when the repository does not have a default environment' do
      it 'returns production' do
        repo = Repository.new(default_environment: '')
        expect(repo.default_environment).to eq 'production'

        repo = Repository.new
        expect(repo.default_environment).to eq 'production'
      end
    end
  end
end
