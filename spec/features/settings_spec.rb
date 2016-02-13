require 'rails_helper'

RSpec.feature 'Settings' do
  fixtures :all
  include Rack::Test::Methods
  let(:app) { SlashDeploy.app }

  scenario 'changing the default environment' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    repo.environment('staging')

    visit repository_edit_path(repo)
    select 'staging', from: 'Default environment'

    expect do
      click_on 'Save Changes'
    end.to change { repo.reload.default_environment }.to('staging')
  end

  scenario 'change the default branch on an environment' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    staging = repo.environment('staging')

    visit repository_environment_edit_path(repo, staging)
    fill_in 'Default Branch', with: 'develop'

    expect do
      click_on 'Save Changes'
    end.to change { staging.reload.default_ref }.to('develop')
  end

  scenario 'enabling auto deployments on an environment' do
    repo = Repository.with_name('baxterthehacker/public-repo')
    staging = repo.environment('staging')

    visit repository_environment_edit_path(repo, staging)
    fill_in 'Automatically Deploy', with: 'refs/heads/develop'

    expect do
      click_on 'Save Changes'
    end.to change { staging.reload.auto_deploy_ref }.to('refs/heads/develop')
  end
end
