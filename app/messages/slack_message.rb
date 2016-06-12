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
    view = ActionView::Base.new(['app/views/messages'], attributes.merge(extra_assigns))
    view.render(file: self.class.to_s.gsub(/Message$/, '').underscore).strip
  end

  def t(key, options = {})
    I18n.t(key, options.merge(scope: [:slack, :messages, self.class.to_s.underscore]))
  end

  def slack_user(user)
    SlackUser.new(user, slack_team)
  end
end
