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
        repo = Repository.with_name('remind101/acme-inc')
        environment = repo.environment('staging')
        expect(environment).to_not be_nil
        expect(environment.name).to eq 'staging'
      end
    end

    context 'when not given a name' do
      it 'returns the default environment' do
        repo = Repository.with_name('remind101/acme-inc')
        environment = repo.environment
        expect(environment).to_not be_nil
        expect(environment.name).to eq 'production'
      end
    end
  end
end
