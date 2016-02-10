# A validator that validates that the given Environment is "unique". This means
# that:
#
#   1. The aliases in the environment are not present in any other environment
#      for the repository.
#   2. The aliases don't match the name of any other environment.
class UniqueEnvironment < ActiveModel::Validator
  def self.validate(environment)
    new.validate(environment)
  end

  def validate(environment)
    # TODO: This is N+1 for each environment.
    environment.aliases.each do |name|
      existing = environment.other_environments_named(name).first
      environment.errors.add(:aliases, :matches_existing_environment, name: existing.name) if existing
    end

    existing = environment.other_environments_named(environment.name).first
    environment.errors.add(:name, :matches_existing_environment, name: existing.name) if existing
  end
end
