require 'rails_helper'

RSpec.describe GenConfig, type: :model do
  it 'generates a yaml config' do
    repo = Repository.with_name('acme-inc/api')
    production = repo.environment('production')
    production.required_contexts = ['ci/circleci', 'container/docker']
    production.configure_auto_deploy('refs/heads/master')

    staging = repo.environment('staging')
    staging.aliases = %w(stage st)
    staging.save!

    repo.environment('bogus')

    expect(GenConfig.gen('acme-inc/api')).to eq <<-EOF
# For information about what configuration options are available, see
# https://slashdeploy.io/docs"
---
environments:
  bogus: {}
  production:
    continuous_delivery:
      ref: refs/heads/master
      required_contexts:
      - ci/circleci
      - container/docker
  staging:
    aliases:
    - stage
    - st
EOF
  end
end
