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

  get "resources/featured" do
    let!(:resource_score) {
      ResourceScore.find_or_create_by!(resource: resource, country: "us", lang: "en") do |rs|
        rs.featured = true
        rs.featured_order = 1
      end
    }

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

      context "inside filter param" do
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

      context "inside filter param" do
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

      context "inside filter param" do
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

    let!(:resource_score) {
      ResourceScore.find_or_create_by!(resource: resource, country: "us", lang: "en") do |rs|
        rs.featured = true
        rs.featured_order = 1
      end
    }
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
        do_request(data: {type: "resource_score", attributes: {featured: true, resource_id: resource.id}})

        expect(status).to be(422)
        json = JSON.parse(response_body)
        expect(json).to have_key("errors")
      end
    end
  end

  delete "resources/featured/:id" do
    requires_authorization

    let(:id) { resource_score.id }
    let!(:resource_score) {
      ResourceScore.find_or_create_by!(resource: resource, country: "us", lang: "en") do |rs|
        rs.featured = true
        rs.featured_order = 1
      end
    }

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

  patch "resources/featured/:id" do
    requires_authorization

    let!(:resource_score) {
      ResourceScore.find_or_create_by!(resource: resource, country: "us", lang: "en") do |rs|
        rs.featured = true
        rs.featured_order = 1
      end
    }
    let(:id) { resource_score.id }
    let(:valid_update_params) do
      {
        data: {
          type: "resource_score",
          attributes: {
            featured_order: 2,
            country: "CA"
          }
        }
      }
    end

    context "with valid parameters" do
      it "updates the featured resource score" do
        do_request(valid_update_params)

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"]["attributes"]["featured-order"]).to eq(2)
        expect(json["data"]["attributes"]["country"]).to eq("CA".downcase)
        expect(json["data"]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
      end
    end

    context "with invalid parameters" do
      it "returns unprocessable entity" do
        do_request(data: {type: "resource_score", attributes: {featured_order: "invalid"}})

        expect(status).to be(422)
        json = JSON.parse(response_body)
        expect(json).to have_key("errors")
      end
    end

    context "when an incorrect ID is sent" do
      let(:id) { "unknownId" }

      it "returns a not found error" do
        do_request(valid_update_params)

        expect(status).to be(404)
      end
    end
  end

  patch "resources/featured/mass_update" do
    requires_authorization

    let(:country) { 'us' }
    let(:lang) { 'en' }
    let(:resource_ids) { [] }
    let(:params) { { country: country, lang: lang, resource_ids: resource_ids } }

    context "with no country and lang params" do
      let(:country) { nil }
      let(:lang) { nil }

      context "when sending an empty array" do
        it "returns an empty array" do
          do_request(params)

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].count).to eq(0)
        end
      end

      context "when sending 1 resource score" do
        let(:resource_ids) { [resource.id] }

        it "returns an error" do
          do_request(params)

          expect(status).to be(422)
        end
      end
    end

    context "with country and lang params" do
      context "with no previous resource score" do
        context "when sending an empty array" do
          it "returns an empty array" do
            do_request(params)
  
            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(0)
          end
        end
  
        context "when sending 1 resource score" do
          let(:resource_ids) { [resource.id] }
  
          it "returns an array with 1 resource score" do
            do_request(params)
  
            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(1)
            expect(json["data"][0]['relationships']['resource']['data']['id']).to eq(resource.id.to_s)
          end
        end
  
        context "when sending more than 1 resource score" do
          let!(:resource2) { Resource.joins(:resource_type).where("resource_types.name != ? AND resources.id NOT IN (?)", resource.resource_type.name, resource.id).first }
          let(:resource_ids) { [resource.id, resource2.id] }

          it "returns an array with more than 1 resource score" do
            do_request(params)
  
            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(2)
            expect(json["data"][0]['relationships']['resource']['data']['id']).to eq(resource.id.to_s)
            expect(json["data"][1]['relationships']['resource']['data']['id']).to eq(resource2.id.to_s)
          end
        end
      end
  
      context "with previous resource scores" do
        let!(:resource2) { Resource.joins(:resource_type).where("resource_types.name != ? AND resources.id NOT IN (?)", resource.resource_type.name, resource.id).first }
        let!(:resource3) { Resource.joins(:resource_type).where("resource_types.name != ? AND resources.id NOT IN (?)", resource.resource_type.name, [resource.id, resource2.id]).first }
        let!(:resource_score) do
          ResourceScore.create!(resource: resource, country: country, lang: lang, featured: true, featured_order: 1)
        end
        let!(:resource_score2) do
          ResourceScore.create!(resource: resource2, country: country, lang: lang, featured: true, featured_order: 2)
        end
  
        context "when sending an empty array" do
          it "returns an array with previous resource scores" do
            do_request(params)
  
            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(2)
            expect(json["data"][0]['relationships']['resource']['data']['id']).to eq(resource_score.resource_id.to_s)
            expect(json["data"][1]['relationships']['resource']['data']['id']).to eq(resource2.id.to_s)
          end
        end
  
        context "when sending 1 resource to replace" do
          let(:resource_ids) { [resource3.id, resource2.id] }

          it "returns an array with the replaced resource score" do
            do_request(params)
  
            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(2)
            expect(json["data"][0]['relationships']['resource']['data']['id']).to eq(resource3.id.to_s)
            expect(json["data"][1]['relationships']['resource']['data']['id']).to eq(resource2.id.to_s)
          end
        end
  
        context "when sending more than 1 resource to replace" do
          let(:resource_ids) { [resource2.id, resource3.id, resource.id] }

          it "returns an array with the replaced resource scores" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(3)
            expect(json["data"][0]['relationships']['resource']['data']['id']).to eq(resource2.id.to_s)
            expect(json["data"][1]['relationships']['resource']['data']['id']).to eq(resource3.id.to_s)
            expect(json["data"][2]['relationships']['resource']['data']['id']).to eq(resource.id.to_s)
          end
        end
      end
    end
  end
end
