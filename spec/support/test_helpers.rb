module TestHelpers
  module_function def stub_request_to_analytics(rspec_context, analytics_status: 200, access_token_status: 200)
    rspec_context.instance_eval do
      analytics_url = "https://analyticsreporting.googleapis.com/v4/reports:batchGet"
      access_token_url = "https://www.googleapis.com/oauth2/v4/token"

      ENV["GOOGLE_ANALYTICS_VIEW_ID"] = "234841169"
      ENV["GOOGLE_API_USE_RAILS_LOGGER"] = "false"

      body = File.read(Rails.root.join("spec", "fixtures", "google_access_token.json"))
      stub_request(:post, access_token_url).to_return(status: access_token_status, body: body, headers: {"Content-Type" => "application/json; charset=UTF-8"})

      body = File.read(Rails.root.join("spec", "fixtures", "google_analytics_stub.json"))
      stub_request(:post, analytics_url).to_return(status: analytics_status, body: body, headers: {"Content-Type" => "application/json; charset=UTF-8"})
    end
  end
end
