require 'spec_helper'

RSpec.describe Hookshot::Router do
  describe '#call' do
    it 'routes to the correct apps' do
      router = Hookshot::Router.new
      router.handle :push, -> (_env) { [200, {}, ['push event']] }
      router.handle :deployment, -> (_env) { [200, {}, ['deployment event']] }

      status, _headers, body = router.call(env_for_event('push'))
      expect(status).to eq 200
      expect(body).to eq ['push event']

      status, _headers, body = router.call(env_for_event('deployment'))
      expect(status).to eq 200
      expect(body).to eq ['deployment event']

      status, _headers, _body = router.call(env_for_event('ping'))
      expect(status).to eq 404
    end
  end

  def env_for_event(event)
    env = Rack::MockRequest.env_for('/')
    env['HTTP_X_GITHUB_EVENT'] = event
    env
  end
end
