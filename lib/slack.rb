module Slack
  autoload :Message,    'slack/message'
  autoload :Attachment, 'slack/attachment'

  module Client
    autoload :Faraday, 'slack/client/faraday'
    autoload :Fake,    'slack/client/fake'

    # A base error for errors coming from slack clients.
    Error = Class.new(StandardError)

    def self.new(kind)
      case kind.try(:to_sym)
      when :slack
        Faraday.build
      else
        Fake.new
      end
    end

    def direct_message(_slack_account, _message)
      fail NotImplementedError
    end
  end
end
