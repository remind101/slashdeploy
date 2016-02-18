module GitHub
  Error = Class.new(StandardError)

  # RedCommitError is an error that's returned when the commit someone is
  # trying to deploy is not green.
  class RedCommitError < Error
    attr_reader :contexts

    def initialize(contexts = [])
      @contexts = contexts
    end

    def failing_contexts
      contexts.select(&:failure?)
    end
  end
end
