class SlackBot < ActiveRecord::Base
  belongs_to :slack_team
end
