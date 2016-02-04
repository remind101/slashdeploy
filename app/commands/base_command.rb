# BaseCommand is a base command for other commands to inherit from. Commands
# should implement the `run` method.
class BaseCommand
  attr_reader :slashdeploy

  def initialize(slashdeploy)
    @slashdeploy = slashdeploy
  end

  def run(_user, _cmd, _params)
    fail NotImplementedError
  end

  def say(template, assigns = {})
    Slash.say render(template, assigns)
  end

  def reply(template, assigns = {})
    Slash.reply render(template, assigns)
  end

  def render(template, assigns = {})
    prefix = self.class.to_s.gsub('Command', '').underscore
    file = "#{prefix}/#{template}"
    view = ActionView::Base.new('app/views/commands', assigns)
    view.render(file: file).strip
  end
end
