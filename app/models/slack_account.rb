# SlackAccount represents a connected Slack account.
class SlackAccount < ActiveRecord::Base
  belongs_to :user
end
