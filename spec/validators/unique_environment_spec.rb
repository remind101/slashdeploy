require 'rails_helper'

RSpec.describe UniqueEnvironment do
  describe '#validate' do
    context 'when there are no other environments in the repository' do
      it 'marks the environment as valid' do
        environment = stub_model(Environment, name: 'staging')
        expect(environment).to receive(:other_environments_named).with('staging').and_return([])
        validate(environment)
        expect(environment.errors).to be_empty
      end
    end

    context 'when an alias matches the name of another environment' do
      it 'marks the environment as invalid' do
        environment = stub_model(Environment, name: 'staging', aliases: ['production'])
        expect(environment).to receive(:other_environments_named).with('production').and_return([stub_model(Environment, name: 'production')])
        expect(environment).to receive(:other_environments_named).with('staging').and_return([])
        validate(environment)
        expect(environment.errors[:aliases]).to eq ['includes the name of an existing environment for this repository']
      end
    end
  end

  def validate(environment)
    described_class.validate(environment)
  end
end
