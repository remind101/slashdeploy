class SlackMessage
  include Virtus.value_object
  include ActionView::Helpers

  values do
    attribute :slack_team, SlackTeam
  end

  def self.build(*args)
    new(*args).to_message
  end

  # Can be overriden by subclasses.
  def to_message
    fail NotImplementedError
  end

  protected

  def text(extra_assigns = {})
    render(nil, extra_assigns)
  end

  def render(file, extra_assigns = {})
    prefix = self.class.to_s.gsub(/Message$/, '').underscore
    if file
      search = ["app/views/messages/#{prefix}"]
    else
      file = prefix
      search = ['app/views/messages']
    end
    view = ActionView::Base.new(search, attributes.merge(extra_assigns))
    view.render(file: file).strip
  end

  def slack_user(user)
    SlackUser.new(user, slack_team)
  end
end
