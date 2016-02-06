require 'rails_helper'

RSpec.describe SlashCommands do
  let(:slashdeploy) { double(SlashDeploy::Service) }
  let(:handler) { described_class.new slashdeploy }

  describe '#route' do
    it 'routes to the correct handler' do
      check_route('help', HelpCommand, {})
      check_route('where remind101/acme-inc', EnvironmentsCommand, 'repository' => 'remind101/acme-inc')
      check_route('lock staging on remind101/acme-inc: Doing stuff', LockCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging', 'message' => ' Doing stuff')
      check_route('lock staging on remind101/acme-inc', LockCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging', 'message' => nil)
      check_route('unlock staging on remind101/acme-inc', UnlockCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging')
      check_route('remind101/acme-inc', DeployCommand, 'repository' => 'remind101/acme-inc', 'force' => nil, 'ref' => nil, 'environment' => nil)
      check_route('remind101/acme-inc!', DeployCommand, 'repository' => 'remind101/acme-inc', 'force' => '!', 'ref' => nil, 'environment' => nil)
      check_route('remind101/acme-inc@topic', DeployCommand, 'repository' => 'remind101/acme-inc', 'ref' => 'topic', 'force' => nil, 'environment' => nil)
      check_route('remind101/acme-inc@topic!', DeployCommand, 'repository' => 'remind101/acme-inc', 'ref' => 'topic', 'force' => '!', 'environment' => nil)
      check_route('remind101/acme-inc to staging', DeployCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging', 'force' => nil, 'ref' => nil)
      check_route('remind101/acme-inc to staging!', DeployCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging', 'force' => '!', 'ref' => nil)
      check_route('remind101/acme-inc to staging', DeployCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging', 'force' => nil, 'ref' => nil)
      check_route('remind101/acme-inc to staging!', DeployCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging', 'force' => '!', 'ref' => nil)
      check_route('remind101/acme-inc@topic to staging', DeployCommand, 'repository' => 'remind101/acme-inc', 'ref' => 'topic', 'environment' => 'staging', 'force' => nil)
      check_route('remind101/acme-inc@topic to staging!', DeployCommand, 'repository' => 'remind101/acme-inc', 'ref' => 'topic', 'environment' => 'staging', 'force' => '!')
    end

    def check_route(text, expected_handler, expected_params)
      h, params = handler.route(Slash::Command.from_params text: text)
      expect(h).to be_a expected_handler
      expect(params).to eq expected_params
    end
  end
end
