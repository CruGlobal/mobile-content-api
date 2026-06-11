require "rails_helper"

describe "routes", type: :request do
  it "redirects to s3" do
    get "/translations/files/test.zip"
    expect(response).to redirect_to("https://mybucket.s3.us-east-1.amazonaws.com/#{Package::TRANSLATION_FILES_PATH}test.zip")
  end

  context("file without extension") do
    it "redirects to s3" do
      get "/translations/files/test"
      expect(response).to redirect_to("https://mybucket.s3.us-east-1.amazonaws.com/#{Package::TRANSLATION_FILES_PATH}test")
    end
  end

  context("CDN host configured") do
    around do |example|
      ENV["MOBILE_CONTENT_API_CDN_HOST"] = "cdn.example.com"
      Rails.application.reload_routes!
      example.run
    ensure
      ENV.delete("MOBILE_CONTENT_API_CDN_HOST")
      Rails.application.reload_routes!
    end

    it "redirects to the CDN" do
      get "/translations/files/test.zip"
      expect(response).to redirect_to("https://cdn.example.com/#{Package::TRANSLATION_FILES_PATH}test.zip")
    end
  end
end
