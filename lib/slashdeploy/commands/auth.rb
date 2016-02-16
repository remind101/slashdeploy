module SlashDeploy
  module Commands
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
        cmd = env['cmd']

        auth = OmniAuth::AuthHash.new(
          provider: 'slack',
          uid: cmd.request.user_id,
          info: {
            nickname: cmd.request.user_name,
            team_id: cmd.request.team_id,
            team_domain: cmd.request.team_domain
          }
        )
        # Attempt to find the user by their slack user id. This is sufficient
        # to authenticate the user, because we're trusting that the request is
        # coming from Slack.
        identity = Identity.find_with_omniauth(auth)

        if identity && identity.user
          env['user'] = SlackUser.new(identity.user, identity.slack_team)
          handler.call(env)
        else
          account = state_encoder.encode(
            id:          cmd.request.user_id,
            user_name:   cmd.request.user_name,
            team_id:     cmd.request.team_id,
            team_domain: cmd.request.team_domain
          )
          url = "/auth/slash?account=#{account}"
          Slash.reply("I don't know who you are on GitHub yet. Please <#{url}|authenticate> then try again.")
        end
      end
    end
  end
end
