require 'rails_helper'

RSpec.describe Environment, type: :model do
  describe '.named' do
    before do
      repo = Repository.with_name('remind101/acme-inc')
      repo.environments.create!(name: 'production', aliases: %w(prod p))
      repo.environments.create!(name: 'staging', aliases: %w(stage s))
    end

    it 'generates expected sql' do
      sql = Environment.named('production').to_sql
      expect(sql).to eq <<-SQL.strip_heredoc.strip
      SELECT "environments".* FROM "environments" WHERE ("environments"."name" = 'production' OR "environments"."aliases" @> '{production}')
      SQL
    end

    it 'finds by name' do
      relation = Environment.named('production')
      expect(relation.count).to eq 1
      expect(relation.first.name).to eq 'production'
    end

    it 'finds by alias' do
      relation = Environment.named('prod')
      expect(relation.count).to eq 1
      expect(relation.first.name).to eq 'production'
    end
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

  describe '#aliases=' do
    it 'filters out aliases that match the name' do
      repo = Repository.with_name('remind101/acme-inc')
      environment = repo.environment('production')
      environment.aliases = %w(production prod)
      expect(environment.aliases).to eq %w(prod)

      environment.update_attributes! aliases: %w(production prod)
      environment.reload
      expect(environment.aliases).to eq %w(prod)
    end

    it 'allows you to set it to nil' do
      repo = Repository.with_name('remind101/acme-inc')
      environment = repo.environment('production')
      environment.aliases = %w(production prod)
      expect(environment.aliases).to eq %w(prod)

      environment.update_attributes! aliases: nil
      environment.reload
      expect(environment.aliases).to eq []
    end

    it 'does not allow you to create aliases that match a different environment for the same repository' do
      repo = Repository.with_name('remind101/acme-inc')
      repo.environments.create!(name: 'production', aliases: %w(prod))

      staging = repo.environments.create!(name: 'staging')
      staging.update_attributes aliases: %w(prod)
      expect(staging.errors[:aliases]).to eq ['includes the name of an existing environment for this repository']
    end

    it 'does not allow you to create an environment that matches the alias of an existing environment' do
      repo = Repository.with_name('remind101/acme-inc')
      repo.environments.create!(name: 'production', aliases: %w(prod))

      staging = repo.environments.create(name: 'prod')
      expect(staging.errors[:name]).to eq ['includes the name of an existing environment for this repository']
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
end
