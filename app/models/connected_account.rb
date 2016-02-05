# ConnectedAccount represents a connected external OAuth account, like GitHub
# and Slack.
class ConnectedAccount < ActiveRecord::Base
  belongs_to :user
end
