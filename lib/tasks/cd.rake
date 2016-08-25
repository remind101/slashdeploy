namespace :cd do
  task :enable, [:repo] => :environment do |t, args|
    repo = Repository.with_name(args[:repo])
    prod = repo.environment('production')
    prod.required_contexts = ['ci/circleci', 'container/docker']
    prod.configure_auto_deploy('refs/heads/master', fallback_user: GitHubAccount.find_by(login: 'ejholmes').user)
  end
end
