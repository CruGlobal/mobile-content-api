# frozen_string_literal: true

require "acceptance_helper"
require "page_client"

resource "Resources" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"
  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  let(:languages_fr_en) { ["fr", "en"] }
  let(:languages_fr) { ["fr"] }
  let(:languages_it) { ["it"] }
  let(:languages_en) { ["en"] }
  let(:countries_fr) { ["FR"] }
  let(:countries_gb) { ["GB"] }
  let(:countries_fr_us) { ["FR", "US"] }
  let(:openness) { [1, 2, 3] }
  let(:confidence) { [1, 2] }

  get "resources/suggestions" do
    before(:each) do
      FactoryBot.create(:tool_group, name: "one")
      FactoryBot.create(:rule_country, tool_group: ToolGroup.first, countries: countries_fr_us)
      FactoryBot.create(:rule_language, tool_group: ToolGroup.first, languages: languages_fr_en)
    end

    # do_request languages: ["en", "es"], country: "fr", openness: "3"

    context "when matching country param contained in country rule with negative rule as false" do
      before do
        RuleCountry.first.update!(negative_rule: false)
        RuleLanguage.first.update!(negative_rule: false)
      end

      it "return coincidences" do
        do_request country: "fr", languages: languages_fr

        expect(status).to be(200)
        expect(JSON.parse(response_body)["data"]).not_to be_nil
        expect(JSON.parse(response_body)["data"].count).to eql 1
      end

      context "plus matching languages with negative rule as false" do
        it "return coincidences" do
          do_request country: "fr", languages: languages_fr_en

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"]).not_to be_nil
          expect(JSON.parse(response_body)["data"].count).to eql 1
        end
      end

      context "plus not matching languages with negative rule as false" do
        before do
          RuleLanguage.first.update!(languages: languages_fr_en)
        end

        it "does not return coincidences" do
          do_request country: "fr", languages: languages_it

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"]).not_to be_nil
          expect(JSON.parse(response_body)["data"].count).to eql 0
        end
      end

      context "plus not matching all languages with negative rule as true" do
        before do
          RuleLanguage.first.update!(languages: languages_en, negative_rule: true)
        end

        it "return coincidences" do
          do_request country: "fr", languages: languages_fr_en

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"]).not_to be_nil
          expect(JSON.parse(response_body)["data"].count).to eql 1
        end
      end

      context "plus matching all languages with negative rule as true" do
        before do
          RuleLanguage.first.update!(languages: languages_fr_en, negative_rule: true)
        end

        it "does not return coincidences" do
          do_request country: "fr", languages: languages_fr_en

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"]).not_to be_nil
          expect(JSON.parse(response_body)["data"].count).to eql 0
        end
      end

      context "plus not matching languages with negative rule as false" do
        it "does not return coincidences" do
          do_request country: "fr", languages: languages_it

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"]).not_to be_nil
          expect(JSON.parse(response_body)["data"].count).to eql 0
        end
      end
    end

    context "when matching country param contained in country rule with negative rule as true" do
      before do
        RuleCountry.first.update!(negative_rule: true)
      end

      it "does not return coincidences" do
        do_request country: "fr", languages: languages_fr_en

        expect(status).to be(200)
        expect(JSON.parse(response_body)["data"]).not_to be_nil
        expect(JSON.parse(response_body)["data"].count).to eql 0
      end
    end

    context "when not matching country param contained in country rule with negative rule as false" do
      before do
        RuleCountry.first.update!(negative_rule: false)
      end

      it "does not return coincidences" do
        do_request country: "gb", languages: languages_fr_en

        expect(status).to be(200)
        expect(JSON.parse(response_body)["data"]).not_to be_nil
        expect(JSON.parse(response_body)["data"].count).to eql 0
      end
    end

    context "when not matching country param contained in country rule with negative rule as true" do
      before do
        RuleCountry.first.update!(negative_rule: true)
        RuleLanguage.first.update!(negative_rule: false)
      end

      context "plus matching languages with negative rule as true" do
        before do
          RuleLanguage.first.update!(negative_rule: true)
        end

        it "does not return coincidences" do
          do_request country: "gb", languages: languages_fr_en

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"]).not_to be_nil
          expect(JSON.parse(response_body)["data"].count).to eql 0
        end
      end

      context "plus matching languages with negative rule as false" do
        before do
          RuleLanguage.first.update!(negative_rule: false)
        end

        it "return coincidences" do
          do_request country: "gb", languages: languages_fr_en

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"]).not_to be_nil
          expect(JSON.parse(response_body)["data"].count).to eql 1
        end
      end
    end
  end

  get "resources/" do
    it "get all resources" do
      do_request

      expect(status).to be(200)
      expect(JSON.parse(response_body)["data"].count).to be(5)
    end

    it "includes no objects by default", document: false do
      do_request

      expect(JSON.parse(response_body)["included"]).to be_nil
    end

    it "sorts by name ascending", document: false do
      do_request

      expect(JSON.parse(response_body)["data"][1]["id"]).to eq("5")
    end

    it "get all resources with system name" do
      do_request "filter[system]": "GodTools"

      expect(status).to be(200)
      expect(JSON.parse(response_body)["data"].count).to be(5)
    end

    it "get all resources, include variations" do
      do_request "filter[system]" => "GodTools", :include => :variants

      expect(status).to be(200)
      json = JSON.parse(response_body)
      metatool = json["data"].detect { |entry| entry["attributes"]["resource-type"] == "metatool" }
      expect(metatool["relationships"]["variants"]["data"]).to match_array([{"id" => "1", "type" => "resource"}, {"id" => "5", "type" => "resource"}])
    end

    context "with translation attributes" do
      let!(:translation) { Resource.first.latest_translations.first }
      let!(:translation_attribute_1) { FactoryBot.create(:translation_attribute, key: "key1", value: "translation content 1", translation: translation) }
      let!(:translation_attribute_2) { FactoryBot.create(:translation_attribute, key: "key2", value: "translation content 2", translation: translation) }

      it "get all resources, include latest-translations" do
        do_request "filter[system]": "GodTools", include: "latest-translations"

        expect(status).to be(200)
        json_body = JSON.parse(response_body)
        expect(json_body["included"].count).to be(5)
        expect(json_body.dig("included").first&.dig("attributes", "attr-key1")).to eq("translation content 1")
        expect(json_body.dig("included").first&.dig("attributes", "attr-key2")).to eq("translation content 2")
      end
    end

    it "only get name and system of resources" do
      do_request "fields[resource]": "name,system"

      expect(status).to be(200)
      data = JSON.parse(response_body)["data"][1]
      expect(data["attributes"].keys).to eq ["name"]
      expect(data["relationships"].keys).to eq ["system"]
    end

    it "get resource with a specific abbreviation" do
      do_request "filter[abbreviation]": "es"

      expect(status).to be(200)
      json = JSON.parse(response_body)
      expect(json["data"].count).to be(1)
      expect(json["data"][0]["attributes"]["abbreviation"]).to eq("es")
    end

    it "get resource with a specific abbreviation, include default-variant" do
      do_request "filter[abbreviation]": "meta", include: "default-variant"

      expect(status).to be(200)
      json = JSON.parse(response_body)
      expect(json["data"].count).to be(1)
      expect(json["included"].count).to be(1)
      expect(json["included"][0]["attributes"]["abbreviation"]).to eq("kgp")
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

    it "get resource, include latest-translations" do
      do_request include: "latest-translations"

      expect(status).to be(200)
      expect(JSON.parse(response_body)["included"].count).to be(3)
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
      do_request data: {type: :resource,
                        attributes: {name: "new resource", abbreviation: "r", system_id: 1, resource_type_id: 1}}

      expect(status).to be(201)
      expect(response_body).not_to be_nil
    end
  end

  context "PUT do" do
    let(:id) { 1 }
    let(:manifest) do
      "<manifest xmlns=\"https://mobile-content-api.cru.org/xmlns/manifest\"
                        xmlns:content=\"https://mobile-content-api.cru.org/xmlns/content\">
       </manifest>"
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

        do_request "keep-existing-phrases": false

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
