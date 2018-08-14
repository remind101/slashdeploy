require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#unlock_all!' do

    # slashdeploy/spec/fixtures/users.yml
    fixtures :users
    let(:user1) { users(:david) }
    let(:user2) { users(:steve) }

    it 'allows david to unlock both environments with unlock_all without messing with steve' do

      repo1 = Repository.with_name('acme-inc/api1')
      repo2 = Repository.with_name('acme-inc/api2')

      # david runs lock repo1 in stage environment.
      repo1_stage = repo1.environment('stage')
      expect { repo1_stage.lock! user1 }
        .to change { repo1_stage.locks.active.count }.from(0).to(1)
        .and change { user1.locks.active.count }.from(0).to(1)

      # david runs lock repo1 in prod environment.
      repo1_prod = repo1.environment('prod')
      expect { repo1_prod.lock! user1 }
        .to change { repo1_prod.locks.active.count }.from(0).to(1)
        .and change { user1.locks.active.count }.from(1).to(2)

      # steve runs lock repo2 in stage environment.
      repo2_stage = repo2.environment('stage')
      expect { repo2_stage.lock! user2 }
        .to change { repo2_stage.locks.active.count }.from(0).to(1)
        .and change { user2.locks.active.count }.from(0).to(1)

      # david runs unlock_all!
      user1.unlock_all!

      # expect david to have no active locks.
      expect(user1.locks.active.count).to eq(0)

      # expect steve to have 1 active locks.
      expect(user2.locks.active.count).to eq(1)

    end
  end
end
