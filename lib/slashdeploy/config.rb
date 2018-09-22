module SlashDeploy
  # Config is a Ruby representation of the .slashdeploy.yml configuration file.
  #
  # Example
  #
  #   ---
  #   environments:
  #     production:
  #       aliases:
  #         - prod
  #       continuous_delivery:
  #         ref: refs/heads/master
  #         required_contexts:
  #           - ci/circleci
  #     staging:
  #       aliases:
  #         - stage
  class Config
    include Virtus.model

    class ContinuousDelivery
      include Virtus.model

      attribute :ref, String
      attribute :required_contexts, Array[String]
    end

    class Environment
      include Virtus.model

      attribute :aliases, Array[String]
      attribute :continuous_delivery, ContinuousDelivery
    end

    attribute :environments, Hash[String => Environment]

    # optional default_environment name.
    attribute :default_environment, String, :default => nil

    # Public: Loads the raw yaml and initializes a new Config object from it.
    #
    # yaml - raw YAML formatted string
    #
    # Returns Config.
    def self.from_yaml(yaml)
      # disable arbirtary class deserialization but allow aliases
      new Psych.safe_load(yaml, [], [], true)
    end
  end
end
