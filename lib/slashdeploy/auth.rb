module SlashDeploy
  # Auth is a slash handler middeware that authenticates the Slack user with GitHub.
  class Auth
    attr_reader :handler

    EXPIRATION = 1.minute

    def initialize(handler, secret)
      @handler = handler
      @secret = secret
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
      account = SlackAccount.find_or_create_from_command_payload(auth_data)
      unless account.user
        account.user = User.new
        account.save!
      end

      env['user'] = SlackUser.new(account.user, account.slack_team)

      begin
        handler.call(env)
      rescue User::MissingGitHubAccount
        # If we don't know this slack user, we'll ask them to authenticate
        # with GitHub. We encode and sign the Slack user id within the state
        # param so we know what slack user they are when the hit the GitHub
        # callback.
        claims = {
          id: account.user.id,
          exp: EXPIRATION.from_now.to_i,
          iat: Time.now.to_i
        }
        jwt = JWT.encode(claims, @secret)
        url = Rails.application.routes.url_helpers.jwt_auth_url(jwt: jwt)
        Slash.reply(Slack::Message.new(text: "I don't know who you are on GitHub yet. Please <#{url}|authenticate> then try again."))
      end
    end
  end
end
