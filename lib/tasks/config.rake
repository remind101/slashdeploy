namespace :config do
  task :generate, [:repo] => :environment do |t, args|
    puts GenConfig.gen(args[:repo])
  end
end
