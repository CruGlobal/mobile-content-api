module TestHelpers
  module_function def stub_request_to_analytics(rspec_context, analytics_status: 200, access_token_status: 200)
    rspec_context.instance_eval do
      analytics_url = "http://test.com/adobe_analytics"
      access_token_url = "https://ims-na1.adobelogin.com/ims/exchange/jwt"

      allow(ENV).to receive(:fetch).with("ADOBE_ANALYTICS_REPORT_URL").and_return(analytics_url)
      allow(ENV).to receive(:fetch).with("ADOBE_ANALYTICS_COMPANY_ID").and_return("4")
      allow(ENV).to receive(:fetch).with("ADOBE_ANALYTICS_CLIENT_ID").and_return("5")
      allow(ENV).to receive(:fetch).with("ADOBE_ANALYTICS_JWT_TOKEN").and_return("jwt-token")
      allow(ENV).to receive(:fetch).with("ADOBE_ANALYTICS_CLIENT_SECRET").and_return("secret")
      allow(ENV).to receive(:fetch).with("ADOBE_ANALYTICS_EXCHANGE_JWT_URL").and_return(access_token_url)

      body = File.read(Rails.root.join("spec", "fixtures", "adobe_access_token.json"))
      stub_request(:post, access_token_url).to_return(status: access_token_status, body: body)

      body = File.read(Rails.root.join("spec", "fixtures", "adobe_analytics_stub.json"))
      stub_request(:post, analytics_url).to_return(status: analytics_status, body: body)
    end
  end
end
