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

  get "users/:id" do
    let(:user) { FactoryBot.create(:user) }
    let(:id) { user.id }
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

  get "users/:id" do
    let(:user) { FactoryBot.create(:user) }
    let(:user2) { FactoryBot.create(:user) }
    let(:id) { user2.id }
    requires_okta_login

    it "returns not authorized for another user" do
      do_request
      expect(status).to eq(401)
    end
  end

  get "users/:id" do
    context "favorites" do
      let(:user) { FactoryBot.create(:user) }
      let(:id) { user.id }
      requires_okta_login

      let(:resource) { Resource.first }
      let(:resource2) { Resource.last }
      let!(:favorite_tool) { FactoryBot.create(:favorite_tool, user_id: user.id, tool_id: resource.id) }
      let!(:favorite_tool2) { FactoryBot.create(:favorite_tool, user_id: user.id, tool_id: resource2.id) }
      requires_okta_login

      it "returns appropriate data" do
        do_request
        expect(status).to eq(200)
        json_response = JSON.parse(response_body)["data"]
        expect(json_response).not_to be_nil
        expect(json_response["id"]).to eq(user.id.to_s)
        expect(json_response["type"]).to eq("user")
        expect(json_response.dig("relationships", "favorite-tools", "data").class).to eq(Array)
        expect(json_response["relationships"]["favorite-tools"]["data"]).to eq([{"type" => "resource", "id" => resource.id.to_s}, {"type" => "resource", "id" => resource2.id.to_s}])
      end
    end
  end
end
