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

  describe '/deploy help' do
    it 'responds with usage' do
      expect_reply(HelpCommand::USAGE)
      deploy 'help'
    end
  end

  describe '/deploy lock' do
    context 'with a message' do
      it 'locks the environment' do
        expect_say('Locked staging on remind101/acme-inc')
        expect(slashdeploy).to receive(:lock_environment).with(nil, LockRequest.new(repository: 'remind101/acme-inc', environment: 'staging', message: "I'm testing some stuff")).and_return(LockResponse.new)
        stub = expect_say('Locked `staging` on remind101/acme-inc')
        deploy "lock staging on remind101/acme-inc: I'm testing some stuff"
        expect(stub).to have_been_requested
      end
    end

    context 'without a message' do
      it 'locks the environment' do
        expect_say('Locked staging on remind101/acme-inc')
        expect(slashdeploy).to receive(:lock_environment).with(nil, LockRequest.new(repository: 'remind101/acme-inc', environment: 'staging')).and_return(LockResponse.new)
        stub = expect_say('Locked `staging` on remind101/acme-inc')
        deploy 'lock staging on remind101/acme-inc'
        expect(stub).to have_been_requested
      end
    end
  end

  describe '/deploy unlock' do
    it 'locks the environment' do
      expect_say('Locked staging on remind101/acme-inc')
      expect(slashdeploy).to receive(:unlock_environment).with(nil, UnlockRequest.new(repository: 'remind101/acme-inc', environment: 'staging'))
      stub = expect_say('Unlocked `staging` on remind101/acme-inc')
      deploy 'unlock staging on remind101/acme-inc'
      expect(stub).to have_been_requested
    end
  end

  describe '/deploy where' do
    it 'responds with the environments that can be deployed to' do
      expect(slashdeploy).to receive(:environments).with(nil, 'remind101/acme-inc').and_return([
        mock_model(Environment, name: 'production')
      ])
      expect_say <<-EOF.strip
I know about these environments for remind101/acme-inc:
* production
EOF
      deploy 'where remind101/acme-inc'
    end
  end

  describe '/deploy' do
    context 'simple' do
      it 'triggers a deployment' do
        req = DeploymentRequest.new repository: 'remind101/acme-inc'
        stub = expect_say('Created deployment request for remind101/acme-inc')
        expect(slashdeploy).to receive(:create_deployment).with(nil, req).and_return(req)
        deploy 'remind101/acme-inc'
        expect(stub).to have_been_requested
      end
    end

    context 'with environment' do
      it 'triggers a deployment' do
        req = DeploymentRequest.new repository: 'remind101/acme-inc', environment: 'staging'
        stub = expect_say('Created deployment request for remind101/acme-inc to staging')
        expect(slashdeploy).to receive(:create_deployment).with(nil, req).and_return(req)
        deploy 'remind101/acme-inc to staging'
        expect(stub).to have_been_requested
      end
    end

    context 'with ref' do
      it 'triggers a deployment' do
        req = DeploymentRequest.new repository: 'remind101/acme-inc', ref: 'topic'
        stub = expect_say('Created deployment request for remind101/acme-inc@topic')
        expect(slashdeploy).to receive(:create_deployment).with(nil, req).and_return(req)
        deploy 'remind101/acme-inc@topic'
        expect(stub).to have_been_requested
      end
    end

    context 'with ref and environment' do
      it 'triggers a deployment' do
        req = DeploymentRequest.new repository: 'remind101/acme-inc', ref: 'topic', environment: 'staging'
        stub = expect_say('Created deployment request for remind101/acme-inc@topic to staging')
        expect(slashdeploy).to receive(:create_deployment).with(nil, req).and_return(req)
        deploy 'remind101/acme-inc@topic to staging'
        expect(stub).to have_been_requested
      end
    end

    context 'when the environment is locked' do
      it 'responds with the lock message' do
        stub = expect_say('`staging` is locked: Testing stuff')
        lock = mock_model(Lock, message: 'Testing stuff')
        expect(slashdeploy).to receive(:create_deployment).with(nil, kind_of(DeploymentRequest)).and_raise(SlashDeploy::EnvironmentLockedError.new(lock))
        deploy 'remind101/acme-inc to staging'
        expect(stub).to have_been_requested
      end
    end

    context 'when there are failing commit status checks' do
      it 'response with a message' do
        stub = expect_say <<-EOF.strip
The following commit status checks failed:
* container/docker
You can ignore commit status checks by using `/deploy remind101/acme-inc to staging!`
EOF
        expect(slashdeploy).to receive(:create_deployment).and_raise(SlashDeploy::RedCommitError.new([
          CommitStatusContext.new(context: 'ci/circleci', state: 'success'),
          CommitStatusContext.new(context: 'container/docker', state: 'failure')
        ]))
        deploy 'remind101/acme-inc to staging'
        expect(stub).to have_been_requested
      end
    end
  end

  def expect_reply(text)
    stub_request(:post, 'http://localhost/')
      .with(body: { 'text' => text })
  end

  def expect_say(text)
    stub_request(:post, 'http://localhost/')
      .with(body: { 'response_type' => 'in_channel', 'text' => text })
  end

  def deploy(text)
    cmd = Slash::Command.new(Slash::Request.new(command: '/deploy', text: text, response_url: 'http://localhost/'))
    response = handler.call('cmd' => cmd)
    cmd.respond response if response # TODO: Do better
  end
end
