# frozen_string_literal: true

require "rails_helper"

describe "ResourceScore edit authorization", type: :request do
  let(:headers) do
    {
      "Accept" => "application/vnd.api+json",
      "Content-Type" => "application/vnd.api+json",
      "Authorization" => AuthToken.encode({user_id: user.id})
    }
  end

  let(:tract) { ResourceType.find_by(name: "tract") || FactoryBot.create(:tract_resource_type) }
  let(:resource) { FactoryBot.create(:resource, resource_type: tract) }
  let(:other_resource) { FactoryBot.create(:resource, resource_type: tract) }
  let(:english) { Language.find_or_create_by!(code: "en") { |l| l.name = "English" } }
  let(:spanish) { Language.find_or_create_by!(code: "es") { |l| l.name = "Spanish" } }

  def grant!(country:, language:)
    FactoryBot.create(:resource_score_permission, user: user, country: country, language: language)
  end

  def create_payload(country:, lang:, resource_id: resource.id)
    {data: {attributes: {resource_id: resource_id, country: country, lang: lang, score: 5}}}.to_json
  end

  describe "an editor granted only us/en" do
    let(:user) { FactoryBot.create(:user, admin: false) }

    before { grant!(country: "us", language: english) }

    it "can create inside its grant" do
      post "/resource_scores", params: create_payload(country: "us", lang: "en"), headers: headers

      expect(response).to have_http_status(:created)
      expect(ResourceScore.find_by(resource_id: resource.id, country: "us")).to be_present
    end

    it "is forbidden from creating in another country" do
      post "/resource_scores", params: create_payload(country: "mx", lang: "en"), headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(ResourceScore.where(country: "mx")).to be_empty
    end

    it "is forbidden from creating in another language" do
      post "/resource_scores", params: create_payload(country: "us", lang: "es"), headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(ResourceScore.where(language: spanish)).to be_empty
    end

    context "with an existing score inside the grant" do
      let!(:score) do
        ResourceScore.create!(resource: resource, country: "us", language: english, score: 5)
      end

      it "can update it in place" do
        patch "/resource_scores/#{score.id}",
          params: {data: {attributes: {score: 9}}}.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(score.reload.score).to eq(9)
      end

      it "can destroy it" do
        delete "/resource_scores/#{score.id}", headers: headers

        expect(response).to have_http_status(:ok)
        expect(ResourceScore.exists?(score.id)).to be false
      end

      it "is forbidden from moving it to an ungranted country" do
        patch "/resource_scores/#{score.id}",
          params: {data: {attributes: {country: "mx"}}}.to_json, headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(score.reload.country).to eq("us")
      end

      it "is forbidden from moving it to an ungranted language" do
        patch "/resource_scores/#{score.id}",
          params: {data: {attributes: {lang: "es"}}}.to_json, headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(score.reload.language).to eq(english)
      end
    end

    context "with an existing score outside the grant" do
      let!(:foreign_score) do
        ResourceScore.create!(resource: other_resource, country: "mx", language: spanish, score: 5)
      end

      it "is forbidden from destroying it" do
        delete "/resource_scores/#{foreign_score.id}", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(ResourceScore.exists?(foreign_score.id)).to be true
      end

      it "is forbidden from capturing it into the grant" do
        patch "/resource_scores/#{foreign_score.id}",
          params: {data: {attributes: {country: "us", lang: "en"}}}.to_json, headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(foreign_score.reload.country).to eq("mx")
      end
    end

    it "is forbidden from mass_update outside the grant" do
      patch "/resource_scores/mass_update",
        params: {data: {attributes: {
          country: "mx", lang: "en", resource_type: "tract", resource_ids: [resource.id]
        }}}.to_json, headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(ResourceScore.where(country: "mx")).to be_empty
    end

    it "is forbidden from mass_update_ranked outside the grant" do
      patch "/resource_scores/mass_update_ranked",
        params: {data: {attributes: {
          country: "mx", lang: "en", resource_type: "tract",
          ranked_resources: [{resource_id: resource.id, score: 3}]
        }}}.to_json, headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(ResourceScore.where(country: "mx")).to be_empty
    end

    it "can mass_update inside the grant" do
      patch "/resource_scores/mass_update",
        params: {data: {attributes: {
          country: "us", lang: "en", resource_type: "tract", resource_ids: [resource.id]
        }}}.to_json, headers: headers

      expect(response).to have_http_status(:ok)
      expect(ResourceScore.find_by(resource_id: resource.id, country: "us").featured_order).to eq(1)
    end
  end

  describe "an editor with a country-wide wildcard grant" do
    let(:user) { FactoryBot.create(:user, admin: false) }

    before { grant!(country: "mx", language: nil) }

    it "can create in any language of that country" do
      post "/resource_scores", params: create_payload(country: "mx", lang: "es"), headers: headers

      expect(response).to have_http_status(:created)
    end

    it "is still confined to that country" do
      post "/resource_scores", params: create_payload(country: "us", lang: "es"), headers: headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "a signed-in user with no grants" do
    let(:user) { FactoryBot.create(:user, admin: false) }

    it "is forbidden, not unauthorized" do
      post "/resource_scores", params: create_payload(country: "us", lang: "en"), headers: headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "an admin" do
    let(:user) { FactoryBot.create(:user, admin: true) }

    it "keeps unrestricted access with no grants at all" do
      post "/resource_scores", params: create_payload(country: "vn", lang: "es"), headers: headers

      expect(response).to have_http_status(:created)
    end
  end

  describe "an anonymous caller" do
    it "is unauthorized on write" do
      post "/resource_scores",
        params: {data: {attributes: {resource_id: resource.id, country: "us", lang: "en"}}}.to_json,
        headers: {"Accept" => "application/vnd.api+json", "Content-Type" => "application/vnd.api+json"}

      expect(response).to have_http_status(:unauthorized)
    end

    it "can still read the index" do
      get "/resource_scores", headers: {"Accept" => "application/vnd.api+json"}

      expect(response).to have_http_status(:ok)
    end
  end
end
