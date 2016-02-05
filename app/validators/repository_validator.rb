# Validates the github repo format (e.g. 'remind101/acme-inc')
class RepositoryValidator < ActiveModel::EachValidator
  def self.check(repository)
    repository =~ /^#{SlashDeploy::GITHUB_REPO_REGEX}$/
  end

  def validate_each(record, attribute, value)
    return if self.class.check(value)
    record.errors[attribute] << 'is not a valid GitHub repository'
  end
end
