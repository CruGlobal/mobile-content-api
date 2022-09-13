# frozen_string_literal: true

require "acceptance_helper"

resource "FavoriteTools" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }
  let(:resource) { Resource.first }
  let(:resource2) { Resource.second }

  post "user/me/relationships/favorite-tools" do
    let(:user) { FactoryBot.create(:user) }
    requires_okta_login

    it "creates new favorites" do
      expect {
        do_request data: [{ "type" => "resource", "id" => resource.id.to_s }, { "type" => "resource", "id" => resource2.id.to_s }]
      }.to change { FavoriteTool.count }.by(2)
      expect(FavoriteTool.pluck(:user_id, :tool_id)).to match_array([[user.id, resource.id], [user.id, resource2.id]])
      json_response = JSON.parse(response_body)["data"]
      expect(json_response).to eq([{"type" => "resource", "id" => resource.id.to_s}, {"type" => "resource", "id" => resource2.id.to_s}])
    end
    it "checks if a favorite already exists" do
      FactoryBot.create(:favorite_tool, user_id: user.id, tool_id: resource.id)
      expect {
        do_request data: [{ "type" => "resource", "id" => resource.id.to_s }, { "type" => "resource", "id" => resource2.id.to_s }]
      }.to change { FavoriteTool.count }.by(1)
      json_response = JSON.parse(response_body)["data"]
      expect(json_response).to eq([{"type" => "resource", "id" => resource.id.to_s}, {"type" => "resource", "id" => resource2.id.to_s}])
    end
    it "returns an error if the tools id is not found" do
      expect {
        do_request data: [{ "type" => "resource", "id" => "-1" }]
      }.to change { FavoriteTool.count }.by(0)
      # TODO add error check here
    end
  end
end
