# Helpers included everywhere.
module ApplicationHelper
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

  # Returns a short 7 character representation of a SHA1 hash.
  def short_sha(sha)
    sha[0...7]
  end

  # Returns a slack formatted link, if a url is provided.
  def slack_link_to(url, text)
    return text unless url.present?
    "<#{url}|#{text}>"
  end

  # Returns ref if it's a named reference (e.g. a branch/tag/etc), otherwise it
  # returns a short representation of the SHA1 hash.
  def short_ref_or_sha(ref, sha)
    return ref if ref != sha
    short_sha sha
  end
end
