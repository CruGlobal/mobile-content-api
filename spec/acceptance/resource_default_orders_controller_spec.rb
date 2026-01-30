# frozen_string_literal: true

require "acceptance_helper"
require "sidekiq/testing"

resource "ResourceDefaultOrders" do
  include ActiveJob::TestHelper

  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"
  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  let!(:resource) { Resource.find_by(id: 1) }
  let!(:other_resource) { Resource.find_by(id: 2) }
  let!(:language_en) { Language.find_or_create_by!(code: "en", name: "English") }
  let!(:language_fr) { Language.find_or_create_by!(code: "fr", name: "French") }
  let!(:language_am) { Language.find_or_create_by!(code: "Am", name: "Amharic") }

  before(:each) do
    ResourceDefaultOrder.delete_all
  end

  get "resource_default_orders" do
    before do
      FactoryBot.create(:resource_default_order, resource: resource, language: language_en)
      FactoryBot.create(:resource_default_order, resource: other_resource, language: language_en)
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

      context "with language not found" do
        it "returns an error" do
          do_request lang: "invalid_lang"

          expect(status).to be(422)
          json = JSON.parse(response_body)
          expect(json).to have_key("errors")
          expect(json["errors"][0]["detail"]).to include("Language not found")
        end
      end

      context "inside filter param" do
        it "returns default order resources for specified language" do
          do_request filter: {lang: "fr"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(0)
        end

        context "with language not found" do
          it "returns an error" do
            do_request filter: {lang: "invalid_lang"}

            expect(status).to be(422)
            json = JSON.parse(response_body)
            expect(json).to have_key("errors")
            expect(json["errors"][0]["detail"]).to include("Language not found")
          end
        end
      end

      context "with a different capitalization" do
        it "returns default order resources for specified language" do
          do_request filter: {lang: "am"}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(0)
        end
      end

      context "with non-existent language" do
        it "returns an error" do
          do_request lang: "non_existent_lang"

          expect(status).to be(422)
          json = JSON.parse(response_body)
          expect(json).to have_key("errors")
          expect(json["errors"][0]["detail"]).to include("Language not found")
        end
      end

      context "with non-existent language inside filter param" do
        it "returns an error" do
          do_request filter: {lang: "non_existent_lang"}

          expect(status).to be(422)
          json = JSON.parse(response_body)
          expect(json).to have_key("errors")
          expect(json["errors"][0]["detail"]).to include("Language not found")
        end
      end
    end

    context "with resource_type filter" do
      let(:resource_type) { resource.resource_type }

      it "returns default order resources for specified resource type" do
        do_request resource_type: resource_type.name.downcase

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"].size).to eq(2)
      end

      context "inside filter param" do
        it "returns default order resources for specified resource type" do
          do_request filter: {resource_type: resource_type.name.downcase}

          expect(status).to be(200)
          json = JSON.parse(response_body)
          expect(json["data"].size).to eq(2)
        end
      end
    end
  end

  post "resource_default_orders" do
    requires_authorization

    let(:valid_params) do
      {
        data: {
          type: "resource_default_order",
          attributes: {
            resource_id: resource.id,
            lang: language_en.code,
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
  end

  delete "resource_default_orders/:id" do
    requires_authorization

    let!(:resource_default_order) do
      FactoryBot.create(:resource_default_order, resource: resource, language: language_en)
    end
    let(:id) { resource_default_order.id }

    it "deletes the default order resource" do
      do_request

      expect(status).to be(200)
      expect(ResourceDefaultOrder.exists?(id)).to be false
    end

    context "when an incorrect ID is sent" do
      let(:id) { "unknownId" }

      it "returns not found" do
        do_request

        expect(status).to be(404)
      end
    end
  end

  patch "resource_default_orders/:id" do
    requires_authorization

    let!(:resource_default_order) do
      FactoryBot.create(:resource_default_order, resource: resource, language: language_en)
    end
    let(:id) { resource_default_order.id }
    let(:valid_update_params) do
      {
        data: {
          type: "resource_default_order",
          attributes: {
            lang: language_fr.code
          }
        }
      }
    end

    context "with valid parameters" do
      it "updates the default order resource" do
        do_request(valid_update_params)

        expect(status).to be(200)
        json = JSON.parse(response_body)
        expect(json["data"]["relationships"]["language"]["data"]["id"]).to eq(language_fr.id.to_s)
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

      it "returns not found" do
        do_request(valid_update_params)

        expect(status).to be(404)
      end
    end
  end

  patch "resource_default_orders/mass_update" do
    requires_authorization

    let(:lang) { "en" }
    let(:resource_ids) { [] }
    let(:resource_type) { ResourceType.find(resource.resource_type_id) }
    let(:params) do
      {data: {attributes: {lang: lang, resource_ids: resource_ids, resource_type: resource_type&.name}}}
    end

    context "with no lang param" do
      let(:lang) { nil }

      context "when sending an empty array" do
        it "raises an error" do
          expect { do_request(params) }.to raise_error(RuntimeError, "Language and Resource Type should be provided")
        end
      end

      context "when sending 1 resource default order" do
        let(:resource_ids) { [resource.id] }

        it "raises an error" do
          expect { do_request(params) }.to raise_error(RuntimeError, "Language and Resource Type should be provided")
        end
      end
    end

    context "with no resource_type param" do
      let(:resource_type) { nil }

      context "when sending an empty array" do
        it "returns an error" do
          expect { do_request(params) }.to raise_error(RuntimeError, "Language and Resource Type should be provided")
        end
      end

      context "when sending 1 resource default order" do
        let(:resource_ids) { [resource.id] }

        it "returns an error" do
          expect { do_request(params) }.to raise_error(RuntimeError, "Language and Resource Type should be provided")
        end
      end
    end

    context "with lang param" do
      context "with no previous resource default order" do
        context "when sending an empty array" do
          it "returns an empty array" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(0)
          end
        end

        context "when sending 1 resource default order" do
          let(:resource_ids) { [resource.id] }

          it "returns an array with 1 resource default order" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(1)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
            expect(json["data"][0]["attributes"]["position"]).to eq(1)
          end
        end

        context "when sending more than 1 resource default order" do
          let(:resource2) { other_resource }
          let(:resource_ids) { [resource.id, resource2.id] }

          it "returns an array with more than 1 resource default order" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(2)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
            expect(json["data"][0]["attributes"]["position"]).to eq(1)
            expect(json["data"][1]["relationships"]["resource"]["data"]["id"]).to eq(resource2.id.to_s)
            expect(json["data"][1]["attributes"]["position"]).to eq(2)
          end
        end
      end

      context "with previous resource default orders" do
        let!(:resource2) { other_resource }
        let!(:resource3) { Resource.find_by(id: 5) }
        let!(:resource_default_order) do
          FactoryBot.create(:resource_default_order, resource: resource, language: language_en, position: 1)
        end
        let!(:resource_default_order2) do
          FactoryBot.create(:resource_default_order, resource: resource2, language: language_en, position: 2)
        end

        context "when sending an empty array" do
          let(:resource_ids) { [] }

          it "deletes all matching resource default orders" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(0)
            expect(ResourceDefaultOrder.exists?(resource_default_order.id)).to be false
            expect(ResourceDefaultOrder.exists?(resource_default_order2.id)).to be false
          end
        end

        context "when sending 1 resource to replace" do
          let(:resource_ids) { [resource3.id, resource2.id] }

          it "returns an array with the replaced resource default orders" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(2)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource3.id.to_s)
            expect(json["data"][0]["attributes"]["position"]).to eq(1)
            expect(json["data"][1]["relationships"]["resource"]["data"]["id"]).to eq(resource2.id.to_s)
            expect(json["data"][1]["attributes"]["position"]).to eq(2)
          end
        end

        context "when sending more than 1 resource to replace" do
          let(:resource_ids) { [resource2.id, resource3.id, resource.id] }

          it "returns an array with the replaced resource default orders" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(3)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource2.id.to_s)
            expect(json["data"][0]["attributes"]["position"]).to eq(1)
            expect(json["data"][1]["relationships"]["resource"]["data"]["id"]).to eq(resource3.id.to_s)
            expect(json["data"][1]["attributes"]["position"]).to eq(2)
            expect(json["data"][2]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
            expect(json["data"][2]["attributes"]["position"]).to eq(3)
          end
        end

        context "when sending the same resource to replace" do
          let(:resource_ids) { [resource.id, resource2.id] }

          it "returns an array with the resource default orders in new positions" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(2)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
            expect(json["data"][0]["attributes"]["position"]).to eq(1)
            expect(json["data"][1]["relationships"]["resource"]["data"]["id"]).to eq(resource2.id.to_s)
            expect(json["data"][1]["attributes"]["position"]).to eq(2)
          end
        end

        context "when omitting a resource from the incoming list" do
          let(:resource_ids) { [resource.id] }

          it "removes the omitted resource default order" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(1)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource.id.to_s)
            expect(json["data"][0]["attributes"]["position"]).to eq(1)
            expect(ResourceDefaultOrder.exists?(resource_default_order2.id)).to be false
          end
        end

        context "when omitting multiple resources from the incoming list" do
          let!(:resource_default_order3) do
            FactoryBot.create(:resource_default_order, resource: resource3, language: language_en, position: 3)
          end
          let(:resource_ids) { [resource2.id] }

          it "removes all omitted resource default orders" do
            do_request(params)

            expect(status).to be(200)
            json = JSON.parse(response_body)
            expect(json["data"].count).to eq(1)
            expect(json["data"][0]["relationships"]["resource"]["data"]["id"]).to eq(resource2.id.to_s)
            expect(json["data"][0]["attributes"]["position"]).to eq(1)
            expect(ResourceDefaultOrder.exists?(resource_default_order.id)).to be false
            expect(ResourceDefaultOrder.exists?(resource_default_order3.id)).to be false
          end
        end
      end
    end
  end
end
