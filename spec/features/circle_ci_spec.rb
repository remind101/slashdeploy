require 'rails_helper'

RSpec.feature 'Auto Deployment' do
  fixtures :all
  let(:github) { instance_double(GitHub::Client) }
  let(:slack) { instance_double(Slack::Client) }

  before do
    allow(SlashDeploy.service).to receive(:github).and_return(github)
    allow(SlashDeploy.service).to receive(:slack).and_return(slack)
  end

  scenario 'receiving a `deployment` event for a repository that has circle ci deployments enable' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    repo.update_attributes! circleci_api_token: '1ed9be19-0e48-48a1-a741-8e244ab1b5af'

    stub_request(:post, "https://circleci.com/api/v1.1/project/github/baxterthehacker/public-repo?circle-token=1ed9be19-0e48-48a1-a741-8e244ab1b5af")
      .with(body: {
        revision: '9049f1265b7d61be4a8904a9a27120d2064dab3b',
        build_parameters: {
          'GITHUB_DEPLOYMENT_ID' => 710692,
          'GITHUB_DEPLOYMENT_ENVIRONMENT' => 'production'
        }
      }, headers: { 'Content-Type' => 'application/json' }).to_return(status: 200, body: "", headers: {})

    deployment_event 'secret'
    expect(last_response.status).to eq 200
  end
end
