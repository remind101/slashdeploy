module GitHub
  Error = Class.new(StandardError)

  # RedCommitError is an error that's returned when the commit someone is
  # trying to deploy is not green.
  class RedCommitError < Error
    attr_reader :contexts

    def initialize(contexts = [])
      @contexts = contexts
    end

    # Returns the contexts that are in a failing, or pending state.
    def bad_contexts
      contexts.select { |context| !context.success? }
    end
  end

  class BadRefError < Error
    attr_reader :ref

    def initialize(ref)
      @ref = ref
    end
  end
end
