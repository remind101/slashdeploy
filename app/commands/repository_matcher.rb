class RepositoryMatcher
  attr_reader :matcher

  def initialize(matcher)
    @matcher = matcher
  end

  def match(env)
    matcher.match(env).tap do |params|
      break unless params

      if params['repository'].present? && !params['repository'].include?('/')
        team = env['user'].slack_team
        if team.github_organization.present?
          params['repository'] = "#{team.github_organization}/#{params['repository']}"
        else
          return nil
        end
      end
    end
  end
end
