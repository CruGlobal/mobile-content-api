# frozen_string_literal: true

require "acceptance_helper"
require "page_client"

resource "Resources" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"
  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  let(:tool_group_one) { FactoryBot.create(:tool_group, name: "one") }

  let(:resource_1) { Resource.find(1) }
  let(:resource_2) { Resource.find(2) }
  let(:resource_3) { Resource.find(3) }
  let(:resource_4) { Resource.find(4) }
  let(:resource_5) { Resource.find(5) }

  let(:languages_fr_en) { ["fr", "en"] }
  let(:languages_fr_it) { ["fr", "it"] }
  let(:languages_fr_es) { ["fr", "es"] }
  let(:languages_fr) { ["fr"] }
  let(:languages_it) { ["it"] }
  let(:languages_en) { ["en"] }
  let(:languages_es) { ["es"] }

  let(:countries_fr) { ["FR"] }
  let(:countries_gb) { ["GB"] }
  let(:countries_nz) { ["NZ"] }
  let(:countries_fr_us) { ["FR", "US"] }
  let(:countries_gb_us_nz) { ["GB", "US", "NZ"] }

  let(:openness_1) { [1] }
  let(:openness_2) { [2] }
  let(:openness_3) { [3] }
  let(:openness_1_2) { [1, 2] }
  let(:openness_2_3) { [2, 3] }
  let(:openness_3_4) { [3, 4] }

  let(:confidence_1) { [1] }
  let(:confidence_2) { [2] }
  let(:confidence_3) { [3] }
  let(:confidence_1_2) { [1, 2] }
  let(:confidence_2_3) { [2, 3] }
  let(:confidence_3_4) { [3, 4] }

  get "resources/suggestions" do
    before(:each) do
      # FactoryBot.create(:rule_country, tool_group: tool_group_one, countries: countries_fr_us)
      FactoryBot.create(:rule_language, tool_group: tool_group_one, languages: languages_fr_en)
      # FactoryBot.create(:rule_praxis, tool_group: tool_group_one, openness: openness_1, confidence: confidence_2)

      ResourceToolGroup.create!(resource_id: resource_1.id, tool_group_id: tool_group_one.id, suggestions_weight: 2.0)
      ResourceToolGroup.create!(resource_id: resource_2.id, tool_group_id: tool_group_one.id, suggestions_weight: 1.5)
      ResourceToolGroup.create!(resource_id: resource_3.id, tool_group_id: tool_group_one.id, suggestions_weight: 1.7)
      ResourceToolGroup.create!(resource_id: resource_4.id, tool_group_id: tool_group_one.id, suggestions_weight: 3.0)
      ResourceToolGroup.create!(resource_id: resource_5.id, tool_group_id: tool_group_one.id, suggestions_weight: 1.0)
    end

    context "when matching a tool group with only language rule" do
      context "if matching none of languages defined in rule" do
        it "does not return coincidences" do
          do_request "filter[country]": "fr", "filter[language]": languages_es

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"].count).to eql 0
        end
      end

      context "if matching any of the languages defined in rule" do
        it "return coincidences" do
          do_request "filter[country]": "fr", "filter[language]": languages_fr_it

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"].count).to eql 5
        end
      end

      context "if matching all of languages defined in rule" do
        it "return coincidences" do
          do_request "filter[country]": "mx", "filter[language]": languages_fr_en

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"].count).to eql 5
        end
      end
    end

    context "when matching a tool group without rules" do
      it "return coincidence" do
        delete_all_rules

        do_request "filter[country]": "fr", "filter[language]": languages_fr, "filter[openness]": 1, "filter[confidence]": 2

        expect(status).to be(200)
        expect(JSON.parse(response_body)["data"].count).to eql 5
      end
    end

    context "when matching tool groups including one without rules" do
      it "return coincidences ordered" do
        delete_all_rules

        do_request "filter[country]": "fr", "filter[language]": languages_fr, "filter[openness]": 1, "filter[confidence]": 2

        expect(status).to be(200)
        expect(JSON.parse(response_body)["data"].count).to eql 5
      end
    end

    context "when matching tool groups" do
      let(:tool_group_two) { FactoryBot.create(:tool_group, name: "two") }
      let(:tool_group_three) { FactoryBot.create(:tool_group, name: "three") }
      let(:tool_group_four) { FactoryBot.create(:tool_group, name: "four") }
      let(:tool_group_five) { FactoryBot.create(:tool_group, name: "five") }

      before do
        RuleCountry.all.each { |obj| obj.update!(negative_rule: false) }
        RuleLanguage.all.each { |obj| obj.update!(negative_rule: false) }
        RulePraxis.all.each { |obj| obj.update!(negative_rule: false) }

        FactoryBot.create(:rule_country, tool_group: tool_group_two, countries: countries_fr_us)
        FactoryBot.create(:rule_language, tool_group: tool_group_two, languages: languages_fr_en)
        FactoryBot.create(:rule_praxis, tool_group: tool_group_two, openness: openness_1, confidence: confidence_2)

        FactoryBot.create(:rule_country, tool_group: tool_group_three, countries: countries_fr)
        FactoryBot.create(:rule_language, tool_group: tool_group_three, languages: languages_fr_es)
        FactoryBot.create(:rule_praxis, tool_group: tool_group_three, openness: openness_1, confidence: confidence_2)

        FactoryBot.create(:rule_country, tool_group: tool_group_four, countries: countries_gb)
        FactoryBot.create(:rule_language, tool_group: tool_group_four, languages: languages_fr_es)
        FactoryBot.create(:rule_praxis, tool_group: tool_group_four, openness: openness_1, confidence: confidence_2)

        ResourceToolGroup.create!(resource_id: resource_4.id, tool_group_id: tool_group_two.id, suggestions_weight: 1.3)
        ResourceToolGroup.create!(resource_id: resource_5.id, tool_group_id: tool_group_two.id, suggestions_weight: 1.0)

        ResourceToolGroup.create!(resource_id: resource_1.id, tool_group_id: tool_group_three.id, suggestions_weight: 2.0)
        ResourceToolGroup.create!(resource_id: resource_2.id, tool_group_id: tool_group_three.id, suggestions_weight: 1.5)
        ResourceToolGroup.create!(resource_id: resource_3.id, tool_group_id: tool_group_three.id, suggestions_weight: 1.1)
        ResourceToolGroup.create!(resource_id: resource_4.id, tool_group_id: tool_group_three.id, suggestions_weight: 1.0)
        ResourceToolGroup.create!(resource_id: resource_5.id, tool_group_id: tool_group_three.id, suggestions_weight: 1.2)
      end

      it "return coincidences ordered" do
        do_request "filter[country]": "fr", "filter[language]": languages_fr, "filter[openness]": 1, "filter[confidence]": 2

        # Result ordered
        # ----------------------------------
        # Knowing God Personally         2.0
        # Satisfied?                     1.5
        # metatool                       1.15
        # Knowing God Personally Variant 1.1
        # Questions About God            1.1

        expect(status).to be(200)
        expect(JSON.parse(response_body)["data"].count).to eql 5
        expect(JSON.parse(response_body)["data"][0]["attributes"]["name"]).to eql "Knowing God Personally"
        expect(JSON.parse(response_body)["data"][1]["attributes"]["name"]).to eql "Satisfied?"
        expect(JSON.parse(response_body)["data"][2]["attributes"]["name"]).to eql "metatool"
        expect(JSON.parse(response_body)["data"][3]["attributes"]["name"]).to eql "Knowing God Personally Variant"
        expect(JSON.parse(response_body)["data"][4]["attributes"]["name"]).to eql "Questions About God"
      end
    end

    context "when matching country param contained in country rule with negative rule as false" do
      before do
        FactoryBot.create(:rule_country, tool_group: tool_group_one, countries: countries_fr_us)
        FactoryBot.create(:rule_praxis, tool_group: tool_group_one, openness: openness_1, confidence: confidence_2)
      end

      it "return coincidences" do
        do_request "filter[country]": "fr", "filter[language]": languages_fr, "filter[openness]": 1, "filter[confidence]": 2

        expect(status).to be(200)

        expect(JSON.parse(response_body)["data"].count).to eql 5
      end

      context "plus matching languages with negative rule as false" do
        it "return coincidences" do
          do_request "filter[country]": "fr", "filter[language]": languages_fr, "filter[openness]": 1, "filter[confidence]": 2

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"].count).to eql 5
        end

        context "plus not matching openness" do
          context "with negative rule as false" do
            it "does not return coincidences" do
              do_request "filter[country]": "fr", "filter[language]": languages_fr_en, "filter[openness]": 2

              expect(status).to be(200)
              expect(JSON.parse(response_body)["data"].count).to eql 0
            end
          end
        end

        context "plus not matching confidence" do
          context "with negative rule as false" do
            it "does not return coincidences" do
              do_request "filter[country]": "fr", "filter[language]": languages_fr_en, "filter[confidence]": 4

              expect(status).to be(200)
              expect(JSON.parse(response_body)["data"].count).to eql 0
            end
          end
        end

        context "plus matching confidence" do
          context "with negative rule as true" do
            before do
              RulePraxis.first.update!(negative_rule: true)
            end
            it "does not return coincidences" do
              do_request "filter[country]": "fr", "filter[language]": languages_fr_en, "filter[confidence]": 2

              expect(status).to be(200)
              expect(JSON.parse(response_body)["data"].count).to eql 0
            end
          end
        end

        context "plus matching openness" do
          context "with negative rule as true" do
            before do
              RulePraxis.first.update!(negative_rule: true)
            end
            it "does not return coincidences" do
              do_request "filter[country]": "gb", "filter[language]": languages_fr, "filter[openness]": 2

              expect(status).to be(200)
              expect(JSON.parse(response_body)["data"].count).to eql 0
            end
          end
        end

        context "plus matching openness" do
          context "with negative rule as false" do
            it "return coincidences" do
              do_request "filter[country]": "fr", "filter[language]": languages_fr, "filter[openness]": 1

              expect(status).to be(200)
              expect(JSON.parse(response_body)["data"].count).to eql 5
            end
          end

          context "with negative rule as true" do
            before do
              RulePraxis.first.update!(negative_rule: true)
            end
            it "does not return coincidences" do
              do_request "filter[country]": "gb", "filter[language]": languages_fr_es, "filter[openness]": 1

              expect(status).to be(200)
              expect(JSON.parse(response_body)["data"].count).to eql 0
            end
          end
        end
      end

      context "plus not matching languages with negative rule as false" do
        before do
          RuleLanguage.first.update!(languages: languages_fr_en)
        end

        it "does not return coincidences" do
          do_request "filter[country]": "fr", "filter[language]": languages_it

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"].count).to eql 0
        end
      end

      context "plus not matching all languages with negative rule as true" do
        before do
          RuleLanguage.first.update!(languages: languages_en, negative_rule: true)
        end

        it "return coincidences" do
          do_request "filter[country]": "fr", "filter[language]": languages_es, "filter[openness]": 1, "filter[confidence]": 2

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"].count).to eql 5
        end
      end

      context "plus matching all languages with negative rule as true" do
        before do
          RuleLanguage.first.update!(languages: languages_fr_en, negative_rule: true)
        end

        it "does not return coincidences" do
          do_request "filter[country]": "fr", "filter[language]": languages_fr_en

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"].count).to eql 0
        end
      end

      context "plus not matching languages with negative rule as false" do
        it "does not return coincidences" do
          do_request "filter[country]": "fr", "filter[language]": languages_it

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"].count).to eql 0
        end
      end
    end

    context "when matching country param contained in country rule with negative rule as true" do
      before do
        FactoryBot.create(:rule_country, tool_group: tool_group_one, countries: countries_fr_us, negative_rule: true)
      end

      it "does not return coincidences" do
        do_request "filter[country]": "fr"

        expect(status).to be(200)
        expect(JSON.parse(response_body)["data"].count).to eql 0
      end
    end

    context "when not matching country param contained in country rule with negative rule as false" do
      before do
        FactoryBot.create(:rule_country, tool_group: tool_group_one, countries: countries_fr_us)
      end
      it "does not return coincidences" do
        do_request "filter[country]": "gb"

        expect(status).to be(200)
        expect(JSON.parse(response_body)["data"].count).to eql 0
      end
    end

    context "when not matching country param contained in country rule with negative rule as true" do
      before do
        FactoryBot.create(:rule_country, tool_group: tool_group_one, countries: countries_fr_us, negative_rule: true)
        FactoryBot.create(:rule_language, tool_group: tool_group_one, languages: languages_fr_es, negative_rule: false)
      end

      context "plus matching languages with negative rule as true" do
        before do
          RuleLanguage.first.update!(negative_rule: true)
        end

        it "does not return coincidences" do
          do_request "filter[country]": "fr", "filter[language]": languages_fr_en

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"].count).to eql 0
        end
      end

      context "plus matching languages with negative rule as false" do
        before do
          RuleLanguage.first.update!(negative_rule: false)
        end

        it "return coincidences" do
          do_request "filter[country]": "it", "filter[language]": languages_fr_en

          expect(status).to be(200)
          expect(JSON.parse(response_body)["data"].count).to eql 5
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

  def delete_all_rules
    RuleCountry.delete_all
    RuleLanguage.delete_all
    RulePraxis.delete_all
  end

  RSpec::Matchers.define :resource_id do |id|
    match { |actual| (actual.id == id) }
  end
end
