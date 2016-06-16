# HelpCommand handles the `/deploy help` subcommand, which prints the usage
# information.
class HelpCommand < BaseCommand
  def run
    Slash.reply HelpMessage.build \
      not_found: params['not_found']
  end
end
