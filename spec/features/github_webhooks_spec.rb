require 'rails_helper'

RSpec.describe 'GitHub Webhooks' do
  fixtures :all
  let(:slack) { instance_double(Slack::Client) }

  before do
    allow(SlashDeploy.service).to receive(:slack).and_return(slack)
  end

  describe 'ping' do
    it 'returns 200' do
      github_event :ping, ''
      expect(last_response.status).to eq 204
    end
  end

  describe 'deployment_status' do
    scenario 'getting slack notifications when deployment statuses change' do
      users(:david).enable_slack_notifications!

      expect(slack).to receive(:direct_message).with(
        slack_accounts(:david),
        Slack::Message.new(attachments: [
          Slack::Attachment.new(
            color: '#ff0',
            mrkdwn_in: ['text'],
            text: 'Deploy <|#710692> of baxterthehacker/public-repo@<https://github.com/baxterthehacker/public-repo/commits/9049f1265b7d61be4a8904a9a27120d2064dab3b|master> to *production* started',
            fallback: 'Deploy started'
          )
        ])
      ).once
      deployment_status_event \
        'secret',
        deployment_status: {
          state: 'pending'
        },
        deployment: {
          creator: {
            id: github_accounts(:david).id
          }
        }

      expect(slack).to receive(:direct_message).with(
        slack_accounts(:david),
        Slack::Message.new(attachments: [
          Slack::Attachment.new(
            color: '#0f0',
            mrkdwn_in: ['text'],
            text: 'Deploy <|#710692> of baxterthehacker/public-repo@<https://github.com/baxterthehacker/public-repo/commits/9049f1265b7d61be4a8904a9a27120d2064dab3b|master> to *production* succeeded',
            fallback: 'Deploy succeeded'
          )
        ])
      ).once
      deployment_status_event \
        'secret',
        deployment_status: {
          state: 'success'
        },
        deployment: {
          creator: {
            id: github_accounts(:david).id
          }
        }
    end
  end
end
