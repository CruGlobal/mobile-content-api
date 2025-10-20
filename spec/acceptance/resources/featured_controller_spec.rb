# frozen_string_literal: true

require "acceptance_helper"
require "sidekiq/testing"

resource "Resources::Featured" do
  include ActiveJob::TestHelper

  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"
  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  let!(:resource) { Resource.first }
  let!(:unfeatured_resource) { Resource.last }
  let!(:resource_score) { FactoryBot.create(:resource_score, resource: resource, featured: true, featured_order: 1, lang: "en", country: "us") }
  let!(:unfeatured_resource_score) { FactoryBot.create(:resource_score, resource: unfeatured_resource, featured: false, featured_order: 1, lang: "en", country: "us") }

  get "resources/featured" do
    context "without filters" do
      it "returns featured resources" do
        do_request include: "resource-score"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["relationships"]["resource-scores"]["data"][0]["id"]).to eq(resource_score.id.to_s)
      end
    end

    context "with language filter" do
      it "returns featured resources for specified language" do
        do_request lang: "fr"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(0)
      end

      context 'inside filter param' do
        it "returns featured resources for specified language" do
          do_request filter: {lang: "fr"}
  
          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(0)
        end
      end
    end

    context "with country filter" do
      it "returns featured resources for specified country" do
        do_request country: "us"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["relationships"]["resource-scores"]["data"][0]["id"]).to eq(resource_score.id.to_s)
      end

      context 'inside filter param' do
        it "returns featured resources for specified country" do
          do_request filter: {country: "us"}
  
          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(1)
          expect(json["data"][0]["relationships"]["resource-scores"]["data"][0]["id"]).to eq(resource_score.id.to_s)
        end
      end
    end

    context "with resource_type filter" do
      let!(:tool_resource_type) { ResourceType.find_by_name("metatool") }
      let!(:tool_resource) { Resource.joins(:resource_type).where(resource_types: {name: "metatool"}).first }
      let!(:tool_score) { FactoryBot.create(:resource_score, resource: tool_resource, featured: true, featured_order: 2) }

      it "returns featured resources for specified resource type" do
        do_request resource_type: "metatool"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
        expect(json["data"][0]["relationships"]["resource-scores"]["data"][0]["id"]).to eq(tool_score.id.to_s)
      end

      context 'inside filter param' do
        it "returns featured resources for specified resource type" do
          do_request filter: {resource_type: "metatool"}
  
          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(1)
          expect(json["data"][0]["relationships"]["resource-scores"]["data"][0]["id"]).to eq(tool_score.id.to_s)
        end
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
        expect(json["data"]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
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

    context "when an incorrect ID is sent" do
      let(:id) { "unknownId" }

      it "returns a not found error" do
        do_request

        expect(status).to be(404)
      end
    end
  end
end
