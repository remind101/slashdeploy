namespace :github do
  task :secret, [:repo] => :environment do |t, args|
    repo = Repository.find_by(name: args[:repo])
    puts repo.github_secret
  end
end
