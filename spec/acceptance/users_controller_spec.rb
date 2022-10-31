# frozen_string_literal: true

require "acceptance_helper"

resource "UsersController" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }
  let(:resource) { Resource.first }
  let(:resource2) { Resource.second }

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

    context "after user deleted" do
      it "returns 401" do
        user.destroy
        do_request
        expect(status).to eq(401)
      end
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

    it "returns forbidden for another user" do
      do_request
      expect(status).to eq(403)
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

  delete "users/:id" do
    let!(:user) { FactoryBot.create(:user) }
    let!(:user2) { FactoryBot.create(:user) }
    let(:resource) { Resource.first }
    let(:resource2) { Resource.last }
    let!(:favorite_tool) { FactoryBot.create(:favorite_tool, user_id: user.id, tool_id: resource.id) }
    let!(:favorite_tool2) { FactoryBot.create(:favorite_tool, user_id: user.id, tool_id: resource2.id) }
    let!(:favorite_tool3) { FactoryBot.create(:favorite_tool, user_id: user2.id, tool_id: resource2.id) }
    let!(:user_counter) { FactoryBot.create(:user_counter, user_id: user.id, counter_name: "c1", count: 50, decayed_count: 50, last_decay: 90.days.ago) }
    let!(:user_counter2) { FactoryBot.create(:user_counter, user_id: user.id, counter_name: "c2", count: 50, decayed_count: 50, last_decay: 90.days.ago) }
    let!(:user_counter3) { FactoryBot.create(:user_counter, user_id: user2.id, counter_name: "c3", count: 50, decayed_count: 50, last_decay: 90.days.ago) }

    context "yourself" do
      let!(:id) { user.id }
      requires_okta_login

      it "deletes successfully" do
        do_request
        expect(status).to eq(204)
        expect(FavoriteTool.all).to eq([favorite_tool3])
        expect(UserCounter.all).to eq([user_counter3])
        expect(User.find_by(id: id)).to be_nil
      end
    end
    context "someone else" do
      let!(:id) {
        user2.id
      }
      requires_okta_login

      it "returns 403" do
        do_request
        expect(status).to eq(403)
      end
    end
    context "can't find the user" do
      let!(:id) { User.maximum(:id) + 1 }
      requires_okta_login

      it "returns 404" do
        do_request
        expect(status).to eq(404)
      end
    end
  end
end
