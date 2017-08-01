require 'spec_helper'
require 'github/app'

RSpec.describe GitHub::App do
  let(:private_key) { OpenSSL::PKey::RSA.new(GITHUB_APP_PEM) }
  let(:time) { double(Time) }
  let(:app) { described_class.new(1234, private_key, time: time) }

  describe '#app_token' do
    it 'generates a jwt signed token' do
      allow(time).to receive(:now).and_return(Time.at(10))
      app.app_token
    end
  end

  describe '#installation_token' do
    it 'generates an access token for the installation' do
      now = Time.at(1499221567)

      # First call makes a request to get a token and caches it.
      stub1 = stub_request(:post, 'https://api.github.com/installations/4321/access_tokens')
              .with(headers: { 'Accept' => 'application/vnd.github.machine-man-preview+json', 'Authorization' => 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpYXQiOjE0OTkyMjE1NjcsImV4cCI6MTQ5OTIyMTYyNywiaXNzIjoxMjM0fQ.F5UMEEtYu-mnl_LTXKfEA3zbfldpc7LvRAsSC8US1ciF17a3cYiHT4L7GzzODiGf5RTCJ966wwzEi0hNZBaAem2H87aWE_xb3uHYuvPkvDFbpmehxHl052fULVA9ATIMX4kHFp3XKfhRiuce6CLzIPEvdCnECx-Ewo4Lp3sOMGjaOTX-7iRczL6_jgjsVHKmMS6swTsmHT_Lc30ftJ5phiOivsV-TJQt0CTUA807cR1j_gTNqsO9on1UnxYfE6uRjvs09nLamjNyWProS8hVngWM-0pQhZznYBrpAetW6ZU7jFfHzZsPdywbP0ueswIKsWo1gRZEVN7a0cImvDmjuw' })
              .to_return(status: 200, body: { 'token': 'v1.1f699f1069f60xxx', 'expires_at': (now + 1.hour).iso8601 }.to_json, headers: { 'Content-Type' => 'application/json' })
      expect(time).to receive(:now).and_return(now)
      expect(app.installation_token(4321).token).to eq 'v1.1f699f1069f60xxx'

      # Subsequent requests use the token from cache.
      expect(time).to receive(:now).and_return(now + 5.minute)
      expect(app.installation_token(4321).token).to eq 'v1.1f699f1069f60xxx'
      expect(time).to receive(:now).and_return(now + 55.minutes)
      expect(app.installation_token(4321).token).to eq 'v1.1f699f1069f60xxx'

      # After the token expires, a new one is generated.
      stub2 = stub_request(:post, 'https://api.github.com/installations/4321/access_tokens')
              .with(headers: { 'Accept' => 'application/vnd.github.machine-man-preview+json', 'Authorization' => 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpYXQiOjE0OTkyMjUxNjcsImV4cCI6MTQ5OTIyNTIyNywiaXNzIjoxMjM0fQ.2la6Fg1EtxVIRWUQj7iGq1t28Udx6ZYRrJkSHJD5ijpxgJq834K9PDtfnhX0Xy7RgwEODjFPCreWQDt0cn-JYMIuZDTyLQfWIfHcjhHU4gZ2ZY2xHrkPHpjG_VUS91qcYD4tM9fIQo95_NCTVK-AK0Tnfl6-u9pzgoXS5q607nE3OpWEkZ3MCkY-HYsqiLXEqT_HycFQNyxtW7MtBy-zjfrMF0ypCVL6jcyK_Tywc6mxn6H3FwTi6_RI1yef29hygH8csDWod-GcShlV_89w7GEYEnnP5oNzDdY7SlfPjxwEYeo0cSRg39wkXMdjncgttS7Pd8sFYkxnaAQEoSxOBQ' })
              .to_return(status: 200, body: { 'token': 'v1.1f699f1069f60xxx', 'expires_at': (now + 1.hour).iso8601 }.to_json, headers: { 'Content-Type' => 'application/json' })
      expect(time).to receive(:now).and_return(now + 60.minutes).twice
      expect(app.installation_token(4321).token).to eq 'v1.1f699f1069f60xxx'

      expect(stub1).to have_been_requested.once
      expect(stub2).to have_been_requested.once
    end
  end
end
