require 'rails_helper'

RSpec.describe RepositoryValidator do
  describe '.check' do
    it 'validates correctly' do
      expect(check('acme-inc/api')).to be_truthy
      expect(check('acme-inc/private_stacks')).to be_truthy
      expect(check('acme-inc/Thing')).to be_truthy
      expect(check('acme-inc/api@master')).to be_falsy
      expect(check('acme-inc/api:master')).to be_falsy
      expect(check('acme-inc')).to be_falsy
      expect(check('acme-inc')).to be_falsy
    end

    def check(repository)
      RepositoryValidator.check repository
    end
  end
end
