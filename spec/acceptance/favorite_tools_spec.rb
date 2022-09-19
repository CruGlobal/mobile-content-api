# frozen_string_literal: true

require "acceptance_helper"

resource "FavoriteTools" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }
  let(:resource) { Resource.first }
  let(:resource2) { Resource.second }

  get "users/me/relationships/favorite-tools" do
    let(:user) { FactoryBot.create(:user) }
    let(:user2) { FactoryBot.create(:user) }
    let!(:favorite1) { FactoryBot.create(:favorite_tool, user_id: user.id, tool_id: resource.id) }
    let!(:favorite2) { FactoryBot.create(:favorite_tool, user_id: user.id, tool_id: resource2.id) }
    let!(:favorite3) { FactoryBot.create(:favorite_tool, user_id: user2.id, tool_id: resource3.id) }
    let(:id) { resource.id.to_s }
    let(:resource3) { Resource.third }
    requires_okta_login

    it "returns an index of all favorited tools" do
      do_request
      json_response = JSON.parse(response_body)["data"]
      expect(json_response).to match_array([{"type" => "resource", "id" => resource.id.to_s}, {"type" => "resource", "id" => resource2.id.to_s}])
    end
  end

  post "users/me/relationships/favorite-tools" do
    let(:user) { FactoryBot.create(:user) }
    requires_okta_login

    it "creates new favorites" do
      expect {
        do_request data: [{"type" => "resource", "id" => resource.id.to_s}, {"type" => "resource", "id" => resource2.id.to_s}]
      }.to change { FavoriteTool.count }.by(2)
      expect(FavoriteTool.pluck(:user_id, :tool_id)).to match_array([[user.id, resource.id], [user.id, resource2.id]])
      json_response = JSON.parse(response_body)["data"]
      expect(json_response).to match_array([{"type" => "resource", "id" => resource.id.to_s}, {"type" => "resource", "id" => resource2.id.to_s}])
    end
    it "succeeds if a favorite is already favorited" do
      FactoryBot.create(:favorite_tool, user_id: user.id, tool_id: resource.id)
      expect {
        do_request data: [{"type" => "resource", "id" => resource.id.to_s}, {"type" => "resource", "id" => resource2.id.to_s}]
      }.to change { FavoriteTool.count }.by(1)
      json_response = JSON.parse(response_body)["data"]
      expect(json_response).to match_array([{"type" => "resource", "id" => resource.id.to_s}, {"type" => "resource", "id" => resource2.id.to_s}])
    end
    it "returns an error if the tools id is not found" do
      expect {
        do_request data: [{"type" => "resource", "id" => "-1"}]
      }.to change { FavoriteTool.count }.by(0)
      json_error = JSON.parse(response_body)["errors"]
      expect(json_error).to eq([["-1", "invalid tool id"]])
    end
  end

  delete "users/me/relationships/favorite-tools" do
    let(:user) { FactoryBot.create(:user) }
    let!(:favorite1) { FactoryBot.create(:favorite_tool, user_id: user.id, tool_id: resource.id) }
    let!(:favorite2) { FactoryBot.create(:favorite_tool, user_id: user.id, tool_id: resource2.id) }
    let(:resource3) { Resource.third }
    requires_okta_login

    it "deletes a favorite" do
      expect {
        do_request data: [{"type" => "resource", "id" => resource.id.to_s}]
      }.to change { FavoriteTool.count }.by(-1)
      expect(FavoriteTool.pluck(:user_id, :tool_id)).to match_array([[user.id, resource2.id]])
      json_response = JSON.parse(response_body)["data"]
      expect(json_response).to match_array([{"type" => "resource", "id" => resource2.id.to_s}])
    end
    it "succeeds if a favorite was not favorited" do
      expect {
        do_request data: [{"type" => "resource", "id" => resource.id.to_s}, {"type" => "resource", "id" => resource3.id.to_s}]
      }.to change { FavoriteTool.count }.by(-1)
      json_response = JSON.parse(response_body)["data"]
      expect(json_response).to match_array([{"type" => "resource", "id" => resource2.id.to_s}])
    end
    it "returns an error if the tools id is not found" do
      expect {
        do_request data: [{"type" => "resource", "id" => "-1"}]
      }.to change { FavoriteTool.count }.by(0)
      json_error = JSON.parse(response_body)["errors"]
      expect(json_error).to match_array([["-1", "invalid tool id"]])
    end
  end
end
