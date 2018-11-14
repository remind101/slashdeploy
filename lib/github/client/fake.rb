module GitHub
  module Client
    class Fake
      attr_reader :requests
      attr_reader :commits, :deployments

      def initialize
        reset
      end

      # Sets the HEAD commit for the given ref.
      # rubocop:disable Style/MethodName
      def HEAD(repo, ref, commit)
        commits[repo][ref] = commit
        commits[repo][commit] = commit
      end

      def create_deployment(user, req)
        fail RedCommitError, [CommitStatusContext.new(context: 'ci', state: CommitStatusContext::FAILURE)] if req.ref == 'failing' && !req.force
        fail RedCommitError, [CommitStatusContext.new(context: 'ci', state: CommitStatusContext::PENDING)] if req.ref == 'pending' && !req.force
        fail BadRefError, req.ref if req.ref == 'non-existent-branch'
        requests << [user, req]
        id = @ids
        @ids += 1

        sha = commits[req.repository][req.ref]
        fail "No HEAD for #{req.ref}. Use `HEAD` to set it first." unless sha

        deployment = Deployment.new(
          id:          id,
          url:         "https://api.github.com/repos/acme-inc/#{req.repository}/deployments/1",
          repository:  req.repository,
          ref:         req.ref,
          sha:         commits[req.repository][req.ref],
          environment: req.environment
        )
        deployments[req.repository] << deployment
        deployment
      end

      def get_deployment(_user, repository, _deployment_id)
        deployments[repository].select{|k| k[:environment].to_s.match("production")}.last
      end

      def last_deployment(_user, repository, environment)
        if environment.nil? 
          deployments[repository].last
        else
          deployments[repository].select{|k| k[:environment].to_s.match(environment)}.last
        end
      end

      # a test which uses this expects nil, to trigger watch dog.
      #   spec/features/commands_spec.rb:
      #     'github deployment does not start after 30 simulated secs and triggers watchdog'
      def last_deployment_status(_user, deployment_url)
        return nil if deployment_url.include? "api_watchdog"

        {
          state: 'success'
        }
      end

      def contents(_repository, _path)
        nil
      end

      def reset
        @ids = 1
        @commits = Hash.new do |commits, repo|
          commits[repo] = {}
        end
        @deployments = Hash.new do |deployments, repo|
          deployments[repo] = []
        end
        @requests = []
      end

      def access?(user, repository)
        fail('Expected a String repository') unless repository =~ SlashDeploy::GITHUB_REPO_REGEX
        return false if user.github_account.login == 'bob'
        true
      end
    end
  end
end
