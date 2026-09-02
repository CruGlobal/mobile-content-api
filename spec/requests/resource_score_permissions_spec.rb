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
    let(:other_editor) { FactoryBot.create(:user, admin: false) }

    it "rejects an anonymous caller" do
      get base, headers: {"Accept" => "application/vnd.api+json"}

      expect(response).to have_http_status(:unauthorized)
    end

    context "reading" do
      before do
        FactoryBot.create(:resource_score_permission, user: editor, country: "us", language: english)
      end

      it "lets an editor read their own grants by id" do
        get base, headers: headers_for(editor)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["meta"]["grants"]).to eq({"us" => ["en"]})
      end

      it "lets an editor read their own grants via me" do
        get "/users/me/resource-score-permissions", headers: headers_for(editor)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["meta"]["grants"]).to eq({"us" => ["en"]})
      end

      it "forbids an editor from reading someone else's grants" do
        get "/users/#{other_editor.id}/resource-score-permissions", headers: headers_for(editor)

        expect(response).to have_http_status(:forbidden)
      end

      it "still lets an admin read anyone's grants" do
        get base, headers: headers_for(admin)

        expect(response).to have_http_status(:ok)
      end
    end

    context "writing" do
      it "rejects an anonymous caller as unauthenticated, not forbidden" do
        post base,
          params: {data: {attributes: {country: "mx", lang: "en"}}}.to_json,
          headers: {"Accept" => "application/vnd.api+json", "Content-Type" => "application/vnd.api+json"}

        expect(response).to have_http_status(:unauthorized)
      end

      it "rejects a non-admin creating a grant for themselves" do
        post base,
          params: {data: {attributes: {country: "mx", lang: "en"}}}.to_json,
          headers: headers_for(editor)

        expect(response).to have_http_status(:forbidden)
        expect(editor.resource_score_permissions).to be_empty
      end

      it "rejects a non-admin replacing their own grant map" do
        patch "#{base}/mass_update",
          params: {data: {attributes: {grants: {"mx" => ["*"]}}}}.to_json,
          headers: headers_for(editor)

        expect(response).to have_http_status(:forbidden)
      end

      it "rejects a non-admin destroying a grant" do
        permission = FactoryBot.create(:resource_score_permission, user: editor, country: "us", language: english)

        delete "#{base}/#{permission.id}", headers: headers_for(editor)

        expect(response).to have_http_status(:forbidden)
        expect(ResourceScorePermission.exists?(permission.id)).to be true
      end
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

    it "serializes lang and links only the language, not the owning user" do
      get base, headers: headers_for(admin)

      rows = JSON.parse(response.body)["data"]
      expect(rows.map { |row| row["attributes"]["lang"] }).to contain_exactly("en", "*")
      expect(rows.map { |row| row["relationships"].keys }.uniq).to eq([["language"]])
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

    it "rejects a missing lang instead of granting the whole country" do
      post base,
        params: {data: {attributes: {country: "us"}}}.to_json,
        headers: headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(editor.resource_score_permissions).to be_empty
    end

    it "rejects a blank lang" do
      post base,
        params: {data: {attributes: {country: "us", lang: ""}}}.to_json,
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

    it "rejects a null language list rather than silently revoking the country" do
      patch "#{base}/mass_update",
        params: {data: {attributes: {grants: {"vn" => nil}}}}.to_json,
        headers: headers_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(editor.resource_score_grants).to eq({"vn" => ["en"]})
    end

    it "rejects an empty language list" do
      patch "#{base}/mass_update",
        params: {data: {attributes: {grants: {"vn" => []}}}}.to_json,
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
