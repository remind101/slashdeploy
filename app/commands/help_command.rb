# HelpCommand handles the `/deploy help` subcommand, which prints the usage
# information.
class HelpCommand < BaseCommand
  USAGE = <<EOF
To deploy a repo to the default environment: /deploy REPO
To deploy a repo to a specific environment: /deploy REPO to ENVIRONMENT
To deploy a repo to a specific branch: /deploy REPO@REF to ENVIRONMENT
To force a deployment, ignoring any commit statuses: /deploy REPO!
To list known environments you can deploy a repo to: /deploy where REPO
To lock an environment: /deploy lock ENVIRONMENT on REPO: MESSAGE
To unlock a previously locked environment: /deploy unlock ENVIRONMENT on REPO
EOF

  def run(_user, _cmd, _params)
    Slash.reply USAGE
  end
end
