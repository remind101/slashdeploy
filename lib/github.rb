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
  end
end
