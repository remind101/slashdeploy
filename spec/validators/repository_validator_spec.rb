require 'rails_helper'

RSpec.describe RepositoryValidator do
  describe '.check' do
    it 'validates correctly' do
      expect(check('remind101/acme-inc')).to be_truthy
      expect(check('remind101/private_stacks')).to be_truthy
      expect(check('remind101/Thing')).to be_truthy
      expect(check('remind101/acme-inc@master')).to be_falsy
      expect(check('remind101/acme-inc:master')).to be_falsy
      expect(check('remind101')).to be_falsy
      expect(check('remind101')).to be_falsy
    end

    def check(repository)
      RepositoryValidator.check repository
    end
  end
end
