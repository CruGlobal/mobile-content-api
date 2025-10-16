# frozen_string_literal: true

require "acceptance_helper"
require "sidekiq/testing"

resource "Resources::Featured" do
  include ActiveJob::TestHelper

  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"
  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  let!(:resource) { FactoryBot.create(:resource) }
  let!(:resource_score) { FactoryBot.create(:resource_score, resource: resource, featured: true, featured_order: 1) }
  let!(:unfeatured_resource_score) { FactoryBot.create(:resource_score, featured: false) }

  get "resources/featured" do
    context "without filters" do
      it "returns featured resources" do
        do_request

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["attributes"]["featured"]).to be true
      end
    end

    context "with language filter" do
      let!(:resource_score_fr) { FactoryBot.create(:resource_score, lang: "fr", featured: true) }

      it "returns featured resources for specified language" do
        do_request "filter[lang]": "fr"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["attributes"]["lang"]).to eq("fr")
      end
    end

    context "with country filter" do
      let!(:resource_score_us) { FactoryBot.create(:resource_score, country: "US", featured: true) }

      it "returns featured resources for specified country" do
        do_request "filter[country]": "US"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["attributes"]["country"]).to eq("US")
      end
    end

    context "with resource_type filter" do
      let!(:tool_resource) { FactoryBot.create(:resource, resource_type: FactoryBot.create(:resource_type, name: "tool")) }
      let!(:tool_score) { FactoryBot.create(:resource_score, resource: tool_resource, featured: true) }

      it "returns featured resources for specified resource type" do
        do_request "filter[resource_type]": "tool"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(tool_resource.id.to_s)
      end
    end
  end

  post "resources/featured" do
    requires_authorization

    let(:valid_params) do
      {
        data: {
          type: "resource_score",
          attributes: {
            resource_id: resource.id,
            lang: "en",
            country: "US",
            featured: true,
            featured_order: 1
          }
        }
      }
    end

    context "with valid parameters" do
      it "creates a new featured resource score" do
        do_request(valid_params)

        expect(status).to be(201)
        json = JSON.parse(response_body)
        expect(json["data"]["attributes"]["featured"]).to be true
        expect(json["data"]["attributes"]["featured_order"]).to eq(1)
      end
    end

    context "with invalid parameters" do
      it "returns unprocessable entity" do
        do_request(data: {type: "resource_score", attributes: {featured: true}})

        expect(status).to be(422)
        json = JSON.parse(response_body)
        expect(json).to have_key("errors")
      end
    end
  end

  delete "resources/featured/:id" do
    requires_authorization

    let(:id) { resource_score.id }

    it "deletes the featured resource score" do
      do_request

      expect(status).to be(200)
      expect(ResourceScore.exists?(id)).to be false
    end

    context "with non-existent resource score" do
      let(:id) { 999999 }

      it "returns not found" do
        do_request

        expect(status).to be(404)
      end
    end
  end
end
