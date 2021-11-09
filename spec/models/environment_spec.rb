require 'rails_helper'

RSpec.describe Environment, type: :model do
  before do
    stub_request(:get, "https://api.github.com/repos/acme-inc/api").
        with(
          headers: {
          'Accept'=>'application/vnd.github.v3+json',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type'=>'application/json',
          'User-Agent'=>'Octokit Ruby Gem 4.16.0'
          }).
        to_return(status: 200, body: {'default_branch': 'main'}.to_json, headers: { 'Content-Type' => 'application/json' })
  end
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
      it 'returns that value if no default_branch is provided' do
         stub_request(:get, "https://api.github.com/repos/acme-inc/api").
        with(
          headers: {
          'Accept'=>'application/vnd.github.v3+json',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type'=>'application/json',
          'User-Agent'=>'Octokit Ruby Gem 4.16.0'
          }).
        to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
        repo = Repository.with_name('acme-inc/api')
        environment = Environment.new(default_ref: 'develop', repository: repo)
        expect(environment.default_ref).to eq 'develop'
      end
    end

    context 'when the environment does not have a default ref' do
      it 'returns the global default' do
        repo = Repository.with_name('acme-inc/api')
        environment = Environment.new(default_ref: '', repository: repo)
        expect(environment.default_ref).to eq 'main'

        environment = Environment.new(repository: repo)
        expect(environment.default_ref).to eq 'main'
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
