# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

task security: [:'brakeman:run']

if ENV['CI']
  task default: [:rubocop, :spec, :security]
else
  task default: [:rubocop, :spec]
end
