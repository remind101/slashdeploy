module SlashDeploy
  module Commands
    # Helpers for generating Slash::Responses with content from ActionViews.
    module Rendering
      def say(template, assigns = {})
        Slash.say render(template, assigns)
      end

      def reply(template, assigns = {})
        Slash.reply render(template, assigns)
      end

      def render(template, assigns = {})
        view = ActionView::Base.new([
          'app/views/commands',
          "app/views/commands/#{view_prefix}"
        ], assigns)
        view.render(file: template).strip
      end

      def view_prefix
        self.class.to_s.gsub(/Command(s)?$/, '').underscore
      end
    end
  end
end
