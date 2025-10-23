# frozen_string_literal: true

require "acceptance_helper"
require "sidekiq/testing"

resource "Resources::DefaultOrder" do
  include ActiveJob::TestHelper

  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"
  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  let!(:resource) { Resource.first }
  let!(:other_resource) { Resource.last }

  before(:each) do
    ResourceDefaultOrder.delete_all
  end

  get "resources/default_order" do
    before do
      FactoryBot.create(:resource_default_order, resource: resource, lang: "en")
      FactoryBot.create(:resource_default_order, resource: other_resource, lang: "en")
    end

    context "without filters" do
      it "returns default order resources" do
        do_request include: "resource-default-orders"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(2)
      end
    end

    context "with language filter" do
      it "returns default order resources for specified language" do
        do_request lang: "fr"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(0)
      end

      context "inside filter param" do
        it "returns default order resources for specified language" do
          do_request filter: {lang: "fr"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(0)
        end
      end
    end

    context "with resource_type filter" do
      let!(:tool_resource_type) { ResourceType.find_by_name("metatool") }
      let!(:tool_resource) { Resource.joins(:resource_type).where(resource_types: {name: "metatool"}).first }
      let!(:tool_order) { FactoryBot.create(:resource_default_order, resource: tool_resource, lang: "en") }

      it "returns default order resources for specified resource type" do
        do_request resource_type: "metatool"

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(1)
      end

      context "inside filter param" do
        it "returns default order resources for specified resource type" do
          do_request filter: {resource_type: "metatool"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(1)
        end
      end
    end
  end

  post "resources/default_order" do
    requires_authorization

    let(:valid_params) do
      {
        data: {
          type: "resource_default_order",
          attributes: {
            resource_id: resource.id,
            lang: "en",
            position: 2
          }
        }
      }
    end

    context "with valid parameters" do
      it "creates a new default order resource" do
        do_request(valid_params)

        expect(status).to be(201)
        json = JSON.parse(response_body)
        expect(json["data"]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
      end
    end

    context "with invalid parameters" do
      it "returns unprocessable entity" do
        do_request(data: {attributes: {type: "resource_default_order"}})

        expect(status).to be(422)
        json = JSON.parse(response_body)
        expect(json).to have_key("errors")
      end
    end
  end

  delete "resources/default_order/:id" do
    requires_authorization

    let!(:resource_default_order) { FactoryBot.create(:resource_default_order, resource: resource, lang: "en") }
    let(:id) { resource_default_order.id }

    it "deletes the default order resource" do
      do_request

      expect(status).to be(200)
      expect(ResourceDefaultOrder.exists?(id)).to be false
    end

    context "when an incorrect ID is sent" do
      let(:id) { "unknownId" }

      it "returns unprocessable entity" do
        do_request

        expect(status).to be(404)
      end
    end
  end

  patch "resources/default_order/:id" do
    requires_authorization

    let!(:resource_default_order) { FactoryBot.create(:resource_default_order, resource: resource, lang: "en") }
    let(:id) { resource_default_order.id }
    let(:valid_update_params) do
      {
        data: {
          type: "resource_default_order",
          attributes: {
            lang: "fr"
          }
        }
      }
    end

    context "with valid parameters" do
      it "updates the default order resource" do
        do_request(valid_update_params)

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"]["attributes"]["lang"]).to eq("fr")
        expect(json["data"]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
      end
    end

    context "with invalid parameters" do
      it "returns unprocessable entity" do
        do_request(data: {type: "resource_default_order", attributes: {position: "invalid"}})

        expect(status).to be(422)
        json = JSON.parse(response_body)
        expect(json).to have_key("errors")
      end
    end

    context "when an incorrect ID is sent" do
      let(:id) { "unknownId" }

      it "returns unprocessable entity" do
        do_request(valid_update_params)

        expect(status).to be(404)
      end
    end
  end
end
