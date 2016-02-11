require 'rails_helper'

RSpec.describe SlashCommands do
  let(:slashdeploy) { double(SlashDeploy::Service) }
  let(:handler) { described_class.new slashdeploy }

  describe '#route' do
    it 'routes to the correct handler' do
      a = double(SlackUser, slack_team: stub_model(SlackTeam, github_organization: 'remind101'))

      check_route(a, 'help', HelpCommand, {})

      check_route(a, 'where remind101/acme-inc', EnvironmentsCommand, 'repository' => 'remind101/acme-inc')
      check_route(a, 'where acme-inc', EnvironmentsCommand, 'repository' => 'remind101/acme-inc')

      check_route(a, 'lock staging on remind101/acme-inc: Doing stuff', LockCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging', 'message' => ' Doing stuff')
      check_route(a, 'lock staging on remind101/acme-inc', LockCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging', 'message' => nil)
      check_route(a, 'lock staging on acme-inc', LockCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging', 'message' => nil)

      check_route(a, 'unlock staging on remind101/acme-inc', UnlockCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging')
      check_route(a, 'unlock staging on acme-inc', UnlockCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging')

      check_route(a, 'boom', BoomCommand, {})

      check_route(a, 'remind101/acme-inc', DeployCommand, 'repository' => 'remind101/acme-inc', 'force' => nil, 'ref' => nil, 'environment' => nil)
      check_route(a, 'remind101/acme-inc!', DeployCommand, 'repository' => 'remind101/acme-inc', 'force' => '!', 'ref' => nil, 'environment' => nil)
      check_route(a, 'remind101/acme-inc@topic', DeployCommand, 'repository' => 'remind101/acme-inc', 'ref' => 'topic', 'force' => nil, 'environment' => nil)
      check_route(a, 'remind101/acme-inc@topic!', DeployCommand, 'repository' => 'remind101/acme-inc', 'ref' => 'topic', 'force' => '!', 'environment' => nil)
      check_route(a, 'remind101/acme-inc to staging', DeployCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging', 'force' => nil, 'ref' => nil)
      check_route(a, 'remind101/acme-inc to staging!', DeployCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging', 'force' => '!', 'ref' => nil)
      check_route(a, 'remind101/acme-inc to staging', DeployCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging', 'force' => nil, 'ref' => nil)
      check_route(a, 'remind101/acme-inc to staging!', DeployCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging', 'force' => '!', 'ref' => nil)
      check_route(a, 'remind101/acme-inc@topic to staging', DeployCommand, 'repository' => 'remind101/acme-inc', 'ref' => 'topic', 'environment' => 'staging', 'force' => nil)
      check_route(a, 'remind101/acme-inc@topic to staging!', DeployCommand, 'repository' => 'remind101/acme-inc', 'ref' => 'topic', 'environment' => 'staging', 'force' => '!')

      check_route(a, 'acme-inc to staging', DeployCommand, 'repository' => 'remind101/acme-inc', 'environment' => 'staging', 'force' => nil, 'ref' => nil)
    end

    def check_route(user, text, expected_handler, expected_params)
      env = { 'cmd' => Slash::Command.from_params(text: text), 'user' => user }
      router = SlashCommands.route
      route = router.route(env)

      expect(route.match(env)).to eq expected_params
      expect(route.handler).to eq expected_handler
    end
  end
end
