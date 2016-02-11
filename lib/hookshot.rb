# Hookshot provides helpers for handling GitHub webhooks.
module Hookshot
  HEADER_GITHUB_EVENT  = 'HTTP_X_GITHUB_EVENT'.freeze
  HEADER_HUB_SIGNATURE = 'HTTP_X_HUB_SIGNATURE'.freeze

  autoload :Router, 'hookshot/router'

  # Signature calculates the SHA1 HMAC signature of the request body.
  def self.signature(body, secret)
    OpenSSL::HMAC.hexdigest('sha1', secret, body)
  end

  # Verifies that the request body matches the secret.
  def self.verify(request, secret)
    body = request.body.read
    sig = "sha1=#{signature(body, secret)}"
    ActiveSupport::SecurityUtils.secure_compare(sig, request.env[HEADER_HUB_SIGNATURE])
  end

  # Returns a rails router compatible constraint matcher that matches the
  # X-GitHub-Event header to ensure it's presence.
  def self.constraint
    -> (request) { request.env[Hookshot::HEADER_GITHUB_EVENT] }
  end
end
