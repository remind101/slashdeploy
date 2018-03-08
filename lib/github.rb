require 'github/errors'

module GitHub
  module Client
    autoload :Octokit, 'github/client/octokit'
    autoload :Fake,    'github/client/fake'

    def self.new(kind)
      case kind.try(:to_sym)
      when :github
        Octokit.new
      else
        Fake.new
      end
    end

    def create_deployment(_user, _req)
      fail NotImplementedError
    end

    def last_deployment(_user, _repository, _environment)
      fail NotImplementedError
    end

    def access?(_user, _repository)
      fail NotImplementedError
    end

    def contents(_repository, _path)
      fail NotImplementedError
    end
  end
end
