require "rails_helper"

describe "routes", type: :request do
  it "redirects to s3" do
    get "/#{Package::TRANSLATION_FILES_PATH}test.zip"
    expect(response).to redirect_to("https://mybucket.s3.us-east-1.amazonaws.com/#{Package::TRANSLATION_FILES_PATH}test.zip")
  end

  context("file without extension") do
    it "redirects to s3" do
      get "/#{Package::TRANSLATION_FILES_PATH}test"
      expect(response).to redirect_to("https://mybucket.s3.us-east-1.amazonaws.com/#{Package::TRANSLATION_FILES_PATH}test")
    end
  end
end
