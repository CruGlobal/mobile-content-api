# frozen_string_literal: true

require "rails_helper"

describe "ResourceScorePermissions management", type: :request do
  let(:admin) { FactoryBot.create(:user, admin: true) }
  let(:editor) { FactoryBot.create(:user, admin: false) }
  let(:english) { Language.find_or_create_by!(code: "en") { |l| l.name = "English" } }
  let(:spanish) { Language.find_or_create_by!(code: "es") { |l| l.name = "Spanish" } }

  def headers_for(user)
    {
      "Accept" => "application/vnd.api+json",
      "Content-Type" => "application/vnd.api+json",
      "Authorization" => AuthToken.encode({user_id: user.id})
    }
  end

  let(:base) { "/users/#{editor.id}/resource-score-permissions" }

  describe "authorization" do
    it "rejects a non-admin" do
      get base, headers: headers_for(editor)

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects an anonymous caller" do
      get base, headers: {"Accept" => "application/vnd.api+json"}

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET index" do
    before do
      FactoryBot.create(:resource_score_permission, user: editor, country: "us", language: english)
      FactoryBot.create(:resource_score_permission, user: editor, country: "mx", language: nil)
    end

    it "lists grants and includes the nested grant map" do
      get base, headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(2)
      expect(json["meta"]["grants"]).to eq({"us" => ["en"], "mx" => ["*"]})
    end
  end

  describe "POST create" do
    it "creates a single grant" do
      post base,
        params: {data: {attributes: {country: "US", lang: "en"}}}.to_json,
        headers: headers_for(admin)

      expect(response).to have_http_status(:created)
      expect(editor.resource_score_permissions.pluck(:country)).to eq(["us"])
    end

    it "creates a country-wide wildcard when lang is *" do
      post base,
        params: {data: {attributes: {country: "mx", lang: "*"}}}.to_json,
        headers: headers_for(admin)

      expect(response).to have_http_status(:created)
      expect(editor.resource_score_permissions.first.language).to be_nil
    end

    it "rejects an unrecognized country code" do
      post base,
        params: {data: {attributes: {country: "uk", lang: "en"}}}.to_json,
        headers: headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(editor.resource_score_permissions).to be_empty
    end

    it "rejects an unknown language code" do
      post base,
        params: {data: {attributes: {country: "us", lang: "zz"}}}.to_json,
        headers: headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(editor.resource_score_permissions).to be_empty
    end
  end

  describe "DELETE destroy" do
    let!(:permission) do
      FactoryBot.create(:resource_score_permission, user: editor, country: "us", language: english)
    end

    it "removes the grant" do
      delete "#{base}/#{permission.id}", headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(editor.resource_score_permissions.reload).to be_empty
    end
  end

  describe "PATCH mass_update" do
    before do
      spanish
      FactoryBot.create(:resource_score_permission, user: editor, country: "vn", language: english)
    end

    it "replaces the whole grant map" do
      patch "#{base}/mass_update",
        params: {data: {attributes: {grants: {"mx" => ["es"], "us" => ["en", "es"]}}}}.to_json,
        headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(editor.resource_score_grants).to eq({"mx" => ["es"], "us" => %w[en es]})
    end

    it "accepts the wildcard" do
      patch "#{base}/mass_update",
        params: {data: {attributes: {grants: {"mx" => ["*"]}}}}.to_json,
        headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(editor.resource_score_grants).to eq({"mx" => ["*"]})
    end

    it "clears every grant when given an empty map" do
      patch "#{base}/mass_update",
        params: {data: {attributes: {grants: {}}}}.to_json,
        headers: headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(editor.resource_score_permissions.reload).to be_empty
    end

    it "rolls back entirely on a bad country, leaving existing grants intact" do
      patch "#{base}/mass_update",
        params: {data: {attributes: {grants: {"us" => ["en"], "uk" => ["en"]}}}}.to_json,
        headers: headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(editor.resource_score_grants).to eq({"vn" => ["en"]})
    end

    it "rejects a duplicate pair in the payload" do
      patch "#{base}/mass_update",
        params: {data: {attributes: {grants: {"us" => %w[en en]}}}}.to_json,
        headers: headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
