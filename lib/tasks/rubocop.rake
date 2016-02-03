begin
  require 'rubocop/rake_task'

  desc 'Run RuboCop on the lib directory'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.options = [
      # Show the name of the cop so we can add a comment to disable it easily.
      '-D'
    ]
  end
rescue LoadError
  # Meh
end
