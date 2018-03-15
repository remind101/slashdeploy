class GenConfig
  def initialize(repo)
    @repo = repo
  end

  def self.gen(repo_name)
    repo = Repository.where(name: repo_name).first!
    fail("Repo already has a .slashdeploy.yml") if repo.config?
    new(repo).to_yaml
  end

  def config
    config = {}
    @repo.environments.order(:name).each do |environment|
      config["environments"] ||= {}
      env = {}

      env["aliases"] = environment.aliases if environment.aliases.present?

      if environment.auto_deploy_ref.present?
        cd = {
          "ref" => environment.auto_deploy_ref
        }
        if environment.required_contexts.present?
          cd["required_contexts"] = environment.required_contexts
        end
        env["continuous_delivery"] = cd
      end

      config["environments"][environment.name] = env
    end

    config
  end

  def to_yaml
    <<-EOF
# For information about what configuration options are available, see
# https://slashdeploy.io/docs"
#{config.to_yaml.strip}
EOF
  end
end
