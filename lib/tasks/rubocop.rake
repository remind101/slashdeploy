begin
  require 'rubocop/rake_task'

  desc 'Run RuboCop on the lib directory'
  RuboCop::RakeTask.new
rescue LoadError
  # Meh
end
