class HelpMessage < SlackMessage
  USAGE = <<EOF
To deploy a repo to the default environment: /deploy REPO
To deploy a repo to a specific environment: /deploy REPO to ENVIRONMENT
To deploy a repo to a specific branch: /deploy REPO@REF to ENVIRONMENT
To force a deployment, ignoring any commit statuses: /deploy REPO!
To list known environments you can deploy a repo to: /deploy where REPO
To lock an environment: /deploy lock ENVIRONMENT on REPO: MESSAGE
To unlock a previously locked environment: /deploy unlock ENVIRONMENT on REPO
To unlock all locks you own: /deploy unlock all
To check if an environment is locked: /deploy check ENVIRONMENT on REPO
EOF

  values do
    attribute :not_found, Boolean
  end

  def to_message
    Slack::Message.new text: text(usage: USAGE)
  end
end
