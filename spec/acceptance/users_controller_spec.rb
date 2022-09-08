# frozen_string_literal: true

require "acceptance_helper"

resource "UsersController" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }
  let(:resource) { Resource.first }
  let(:resource2) { Resource.second }

  let(:structure) { FactoryBot.attributes_for(:user_counter)[:structure] }

  get "users/me" do
    let(:user) { FactoryBot.create(:user) }
    requires_okta_login

    it "returns appropriate data" do
      do_request
      expect(status).to eq(200)
      json_response = JSON.parse(response_body)["data"]
      expect(json_response).not_to be_nil
      # example response: "{\"data\":{\"id\":\"3032\",\"type\":\"user\",\"attributes\":{\"sso-guid\":\"00ee5990-e16c-4f40-b450-7dd4d18ffc9b\",\"created-at\":\"2022-09-08T16:49:56.584Z\"}}}"
      expect(json_response["id"]).to eq(user.id.to_s)
      expect(json_response["type"]).to eq("user")
      expect(json_response["attributes"]["sso-guid"]).to eq(user.sso_guid)
      expect(json_response["attributes"]["created-at"]).to eq(user.created_at.iso8601)
    end
  end
end
