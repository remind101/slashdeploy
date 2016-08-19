namespace :locks do
  task :active => :environment do
    locks = Lock.active
    locks.each do |lock|
      puts "#{lock.user.username}\t#{lock.repository}\t#{lock.environment}"
    end
  end
end
