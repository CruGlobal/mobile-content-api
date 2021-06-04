# frozen_string_literal: true

require "acceptance_helper"
require "page_client"

resource "Resources" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"
  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  get "resources/" do
    it "get all resources" do
      do_request

      expect(status).to be(200)
      expect(JSON.parse(response_body)["data"].count).to be(3)
    end

    it "includes no objects by default", document: false do
      do_request

      expect(JSON.parse(response_body)["included"]).to be_nil
    end

    it "sorts by name ascending", document: false do
      do_request

      expect(JSON.parse(response_body)["data"][1]["id"]).to eq("3")
    end

    it "get all resources with system name" do
      do_request 'filter[system]': "GodTools"

      expect(status).to be(200)
      expect(JSON.parse(response_body)["data"].count).to be(3)
    end

    it "get all resources, include translations" do
      do_request 'filter[system]': "GodTools", include: :translations

      expect(status).to be(200)
      expect(JSON.parse(response_body)["included"].count).to be(9)
    end

    it "only get name and system of resources" do
      do_request 'fields[resource]': "name,system"

      expect(status).to be(200)
      data = JSON.parse(response_body)["data"][1]
      attrs = data["attributes"]
      expect(attrs.keys).to eq ["name"]
      relationships = data["relationships"]
      expect(relationships.keys).to eq ["system"]
    end
  end

  get "resources/:id" do
    let(:id) { 1 }

    it "get resource" do
      do_request

      expect(status).to be(200)
      expect(JSON.parse(response_body)["data"]["attributes"].size).to be(9)
    end

    it "includes no objects by default", document: false do
      do_request

      expect(JSON.parse(response_body)["included"]).to be_nil
    end

    it "get resource, include translations" do
      do_request include: :translations

      expect(status).to be(200)
      expect(JSON.parse(response_body)["included"].count).to be(4)
    end

    it "has custom attributes", document: false do
      do_request

      attrs = JSON.parse(response_body)["data"]["attributes"]
      expect(attrs["attr-banner-image"]).to eq("this is a location")
      expect(attrs["attr-translate-me"]).to eq("base language")
    end

    it "has total shares", document: false do
      do_request

      attrs = JSON.parse(response_body)["data"]["attributes"]
      expect(attrs["total-views"]).to be(1268)
    end
  end

  post "resources" do
    requires_authorization

    it "create a resource" do
      header "Authorization", :authorization

      do_request data: {type: :resource,
                        attributes: {name: "new resource", abbreviation: "r", system_id: 1, resource_type_id: 1}}

      expect(status).to be(201)
      expect(response_body).not_to be_nil
    end
  end

  context "PUT do" do
    let(:id) { 1 }
    let(:manifest) do
      '<manifest xmlns="https://mobile-content-api.cru.org/xmlns/manifest"
                        xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
       </manifest>'
    end

    put "resources/:id" do
      requires_authorization

      it "updates resource and creates new attributes" do
        do_request data: {type: :resource, attributes: {:description => "hello, world", :"attr-language-attribute" => "language_value",
                                                        "attr-something-else" => "some_other_value", :manifest => manifest}}

        expect(status).to be(200)
        expect(response_body).not_to be_nil
        resource = Resource.find(id)
        expect(resource.description).to eq("hello, world")
        attributes = resource.resource_attributes.pluck(:key, :value).to_h
        expect(attributes).to eq({
          "banner_image" => "this is a location",
          "language_attribute" => "language_value",
          "something_else" => "some_other_value",
          "translate_me" => "base language"
        })
        expect(JSON.parse(response_body)["data"]).not_to be_nil
      end
      context "attribute present" do
        let!(:something_else_attribute) { FactoryBot.create(:attribute, resource_id: id, key: "something_else", value: "current_value") }

        it "updates resource and updates existing attributes" do
          do_request data: {type: :resource, attributes: {:description => "hello, world", :"attr-language-attribute" => "language_value",
                                                          "attr-something-else" => 2, :manifest => manifest}}

          expect(status).to be(200)
          expect(response_body).not_to be_nil
          resource = Resource.find(id)
          expect(resource.description).to eq("hello, world")
          attributes = resource.resource_attributes.pluck(:key, :value).to_h
          expect(attributes).to eq({
            "banner_image" => "this is a location",
            "language_attribute" => "language_value",
            "something_else" => "2",
            "translate_me" => "base language"
          })
          expect(JSON.parse(response_body)["data"]).not_to be_nil
        end

        it "updates resource and deletes attributes" do
          do_request data: {type: :resource, attributes: {:description => "hello, world", :"attr-language-attribute" => "language_value",
                                                          "attr-something-else" => nil, :manifest => manifest}}

          expect(status).to be(200)
          expect(response_body).not_to be_nil
          resource = Resource.find(id)
          expect(resource.description).to eq("hello, world")
          attributes = resource.resource_attributes.pluck(:key, :value).to_h
          expect(attributes).to eq({
            "banner_image" => "this is a location",
            "language_attribute" => "language_value",
            "translate_me" => "base language"
          })
          expect(JSON.parse(response_body)["data"]).not_to be_nil
        end
      end
    end

    put "resources/:id/onesky" do
      parameter "keep-existing-phrases",
        "Query string parameter.  If false, deprecate phrases not pushed to OneSky in this update."

      requires_authorization

      it "update resource in OneSky" do
        mock_page_client(id)

        do_request 'keep-existing-phrases': false

        expect(status).to be(204)
        expect(response_body).to be_empty
      end
    end
  end

  private

  def mock_page_client(resource_id)
    page_client = double
    allow(page_client).to receive(:push_new_onesky_translation).with(false)
    allow(PageClient).to receive(:new).with(resource_id(resource_id), "en").and_return(page_client)
  end

  RSpec::Matchers.define :resource_id do |id|
    match { |actual| (actual.id == id) }
  end
end
