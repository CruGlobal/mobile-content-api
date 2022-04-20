require "rails_helper"

describe "routes", type: :request do
  it "redirects to s3" do
    get "/translations/files/test.zip"
    expect(response).to redirect_to("https://mybucket.s3.us-east-1.amazonaws.com/translations/files/test.zip")
  end

  context("file without extension") do
    it "redirects to s3" do
      get "/translations/files/test"
      expect(response).to redirect_to("https://mybucket.s3.us-east-1.amazonaws.com/translations/files/test")
    end
  end
end
