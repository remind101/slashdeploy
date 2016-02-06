require 'virtus'
require 'active_support'
require 'active_support/core_ext'

# Slash is a Ruby library for handling slack slash commands.
module Slash
  autoload :Request,  'slash/request'
  autoload :Response, 'slash/response'
  autoload :Command,  'slash/command'
  autoload :Rack,     'slash/rack'

  # Middleware for wrapping handlers
  module Middleware
    autoload :Verify, 'slash/middleware/verify'
  end

  # Errors from the Slash library.
  Error = Class.new(StandardError)

  UnverifiedError = Class.new(Error)

  def self.say(text)
    Response.new in_channel: true, text: text
  end

  def self.reply(text)
    Response.new in_channel: false, text: text
  end
end
