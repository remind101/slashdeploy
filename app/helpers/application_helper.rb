# Helpers included everywhere.
module ApplicationHelper
  def authorize_url
    client = Rails.configuration.x.oauth.github
    client.auth_code.authorize_url(state: 'foo')
  end
end
