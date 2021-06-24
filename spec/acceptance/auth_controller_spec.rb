# frozen_string_literal: true

require "acceptance_helper"

resource "Auth" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"
  let(:type) { "auth-token" }
  let(:raw_post) { params.to_json }
  let(:valid_code) { 123_456 }
  let(:valid_access_token) { "okta_access_token_definitely_a_jwt" }
  let(:user) { FactoryBot.create(:user) }

  post "auth/" do
    it "create a token with valid code" do
      do_request data: {type: type, attributes: {code: valid_code}}

      expect(status).to be(201)
    end

    it "create a token with invalid code" do
      do_request data: {type: type, attributes: {code: 999_999}}

      expect(status).to be(400)
    end

    it "create a token with expired code" do
      allow(AccessCode).to(
        receive(:find_by).with(code: valid_code).and_return(AccessCode.new(expiration: DateTime.now.utc - 1.second))
      )

      do_request data: {type: type, attributes: {code: valid_code}}

      expect(status).to be(400)
    end

    it "create a token with a valid Okta access_token" do
      allow(Okta).to receive(:find_user_by_access_token).with(valid_access_token).and_return(user)

      do_request data: {type: type, attributes: {okta_access_token: valid_access_token}}

      expect(status).to be(201)
    end

    it "returns error with a expired Okta access_token" do
      allow(Okta).to receive(:find_user_by_access_token).with(valid_access_token).and_raise(Okta::FailedAuthentication, "expired signature")

      do_request data: {type: type, attributes: {okta_access_token: valid_access_token}}

      expect(status).to be(400)
    end
  end
end
