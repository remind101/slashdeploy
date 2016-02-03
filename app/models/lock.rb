# Lock represents a lock obtained on an environment.
class Lock < ActiveRecord::Base
  belongs_to :environment

  def self.for_environment(repository, environment)
    where(environments: { repository: repository, name: environment }, active: true).includes(:environment).first
  end
end
