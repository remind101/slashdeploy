module SlashDeploy
  # Auth is a slash handler middeware that authenticates the Slack user with GitHub.
  class Auth
    attr_reader :handler
    attr_reader :client
    attr_reader :state_encoder

    def initialize(handler, oauth_client, state_encoder)
      @handler = handler
      @client = oauth_client
      @state_encoder = state_encoder
    end

    def call(env)
      case env['type']
      when 'cmd'
        auth_data = env['cmd']
      when 'action'
        auth_data = env['action']
      end

      # Attempt to find the user by their slack user id. This is sufficient
      # to authenticate the user, because we're trusting that the request is
      # coming from Slack.
      user = User.find_by_slack(auth_data.user_id)
      if user
        team = SlackTeam.find_or_initialize_by(id: auth_data.team_id) do |t|
          t.domain = auth_data.team_domain
        end
        env['user'] = SlackUser.new(user, team)
        handler.call(env)
      else
        # If we don't know this slack user, we'll ask them to authenticate
        # with GitHub. We encode and sign the Slack user id within the state
        # param so we know what slack user they are when the hit the GitHub
        # callback.
        state = state_encoder.encode(
          user_id:     auth_data.user_id,
          user_name:   auth_data.user_name,
          team_id:     auth_data.team_id,
          team_domain: auth_data.team_domain
        )
        url = client.auth_code.authorize_url(state: state, scope: 'repo_deployment')
        Slash.reply(Slack::Message.new(text: "I don't know who you are on GitHub yet. Please <#{url}|authenticate> then try again."))
      end
    end
  end
end
