require 'virtus'
require 'active_support'
require 'active_support/core_ext'

# Slash is a Ruby library for handling slack slash commands.
module Slash
  autoload :Handler,       'slash/handler'
  autoload :Request,       'slash/request'
  autoload :Action,        'slash/action'
  autoload :ActionPayload, 'slash/action_payload'
  autoload :Response,      'slash/response'
  autoload :Command,       'slash/command'
  autoload :Rack,          'slash/rack'
  autoload :Router,        'slash/router'
  autoload :Route,         'slash/route'

  module Matcher
    autoload :Regexp, 'slash/matcher/regexp'
  end

  # Middleware for wrapping handlers
  module Middleware
    autoload :Verify,        'slash/middleware/verify'
    autoload :NormalizeText, 'slash/middleware/normalize_text'
    autoload :Logging,       'slash/middleware/logging'
  end

  # Errors from the Slash library.
  Error = Class.new(StandardError)

  UnverifiedError = Class.new(Error)

  def self.say(message)
    Response.new in_channel: true, message: message
  end

  def self.reply(message)
    Response.new in_channel: false, message: message
  end

  def self.match_regexp(re)
    Matcher::Regexp.new(re)
  end
end
