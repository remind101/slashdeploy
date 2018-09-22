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
    # First step, check the aliases in this environment and make sure there's
    # no other environment that matches.
    # TODO: This is N+1 for each environment.
    environment.aliases.each do |name|
      check environment, :aliases, name
    end

    # Second step, check the name of this environment and make sure there's not
    # other environment that matches.
    check environment, :name, environment.name
  end

  private

  def check(environment, field, name)
    existing = environment.other_environments_named(name).first
    environment.errors.add(field, :matches_existing_environment, name: existing.name) if existing
  end
end
