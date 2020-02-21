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
      stub1 = stub_request(:post, "https://api.github.com/app/installations/4321/access_tokens").
         with(
           body: "{}",
           headers: {
       	  'Accept'=>'application/vnd.github.machine-man-preview+json',
       	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	  'Authorization'=>'Bearer eyJhbGciOiJSUzI1NiJ9.eyJpYXQiOjE0OTkyMjE1NjcsImV4cCI6MTQ5OTIyMTYyNywiaXNzIjoxMjM0fQ.pItH_NZcXZgwrQ2jTVHbGbCIScOmc1rp35NLzVkWqFJrRSaqdaUoxC_u0wrFJeaou2gswqPjXunVAnNmmr06VmaHK1j_0yKhXWy3xFKBIzXG4R9_cKUvTp2L0peE7DCg5Z-33p1sx7_Jw5tt4Lzn6rEns7sMpeN3QQY-KyKwgGlZppM1Adum5vVceu-Ui7Zzd2GAmmTKKbDxaEzm74K-8w1qpWYbSNfE9ZFLUWKxyGrJM1sOqK7m6l1CCgBRD4b_ufYjpVt2aVTNzylwz6fIYT6E9N_LA9IVCQlr4ygc8JFt2ZYFXbbRptPTIWQDDSEqMaGxQMQ_258gxwM7D9gtkQ',
       	  'Content-Type'=>'application/json',
       	  'User-Agent'=>'Octokit Ruby Gem 4.16.0'
           }).to_return(status: 200, body: { 'token': 'v1.1f699f1069f60xxx', 'expires_at': (now + 1.hour).iso8601 }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect(time).to receive(:now).and_return(now)
      expect(app.installation_token(4321).token).to eq 'v1.1f699f1069f60xxx'

      # Subsequent requests use the token from cache.
      expect(time).to receive(:now).and_return(now + 5.minute)
      expect(app.installation_token(4321).token).to eq 'v1.1f699f1069f60xxx'
      expect(time).to receive(:now).and_return(now + 55.minutes)
      expect(app.installation_token(4321).token).to eq 'v1.1f699f1069f60xxx'

      # After the token expires, a new one is generated.
      stub2 = stub_request(:post, "https://api.github.com/app/installations/4321/access_tokens").
         with(
           body: "{}",
           headers: {
       	  'Accept'=>'application/vnd.github.machine-man-preview+json',
       	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	  'Authorization'=>'Bearer eyJhbGciOiJSUzI1NiJ9.eyJpYXQiOjE0OTkyMjUxNjcsImV4cCI6MTQ5OTIyNTIyNywiaXNzIjoxMjM0fQ.tR_fh9n3wys3TzjoteAj3ITGSFwYfBwuGfhVQUNDIWJPIs76H8sGRBTcHeUJPmcEfvGWhPf82uY8NrcjWyjyVmgdk-ahGSkrESHdY3nZJfX7WXJvOvIEM-8NuCyGFhJ2CYyPM0g0PThh_F8StbMI4TQ_mqVXuXk2TJowcxkzaYyG8vUMpiXENWqcEZExCPCnH6s5agxKDYyPuCBldT5ouiSeOhgwSc4xR5Iu3v6rrrz1nuhmUMnR9hVhJ5zn1c6Aw1BqF0nBHr3cLCaPOAd2xjm9poSnxY5JF82j45Xf6PVjreju2RPT7m9_HjZOOE_8vz1FgZlPSH2QP_qL24tgrA',
       	  'Content-Type'=>'application/json',
       	  'User-Agent'=>'Octokit Ruby Gem 4.16.0'
           }).to_return(status: 200, body: { 'token': 'v1.1f699f1069f60xxx', 'expires_at': (now + 1.hour).iso8601 }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect(time).to receive(:now).and_return(now + 60.minutes).twice
      expect(app.installation_token(4321).token).to eq 'v1.1f699f1069f60xxx'

      expect(stub1).to have_been_requested.once
      expect(stub2).to have_been_requested.once
    end
  end
end
