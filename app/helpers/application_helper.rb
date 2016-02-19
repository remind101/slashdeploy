# Helpers included everywhere.
module ApplicationHelper
  def authorize_url
    client = Rails.configuration.x.oauth.github
    client.auth_code.authorize_url(state: 'foo')
  end

  def feedback_email
    mail_to(Rails.configuration.x.feedback_email)
  end

  def add_to_slack
    link_to '/slack/install' do
      image_tag \
        'https://platform.slack-edge.com/img/add_to_slack.png',
        alt: 'Add to Slack',
        height: '40',
        width: '139',
        srcset: 'https://platform.slack-edge.com/img/add_to_slack.png 1x, https://platform.slack-edge.com/img/add_to_slack@2x.png 2x'
    end
  end
end
