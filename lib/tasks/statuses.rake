namespace :statuses do
  task :prune, [:limit] => :environment do |t, args|
    args.with_defaults(limit: 100)
    limit = args[:limit].to_i

    statuses = Status.pruneable.order(:id).limit(limit)
    print "Pruning #{statuses.count} statuses. Continue? (y/n) "
    if STDIN.gets.strip == "y"
      statuses.destroy_all
    else
      puts "Aborting"
    end
  end
end
