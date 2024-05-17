# frozen_string_literal: true

require "acceptance_helper"

resource "ToolGroups" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }
  let(:languages) { ["es", "en"] }
  let(:countries) { ["AR", "ES"] }
  let(:openness) { [1, 2, 3] }
  let(:confidence) { [1, 2] }
  let(:metatool_resource_type) { ResourceType.find_by(name: "metatool") }
  let(:resource) { FactoryBot.create(:resource, system_id: 1, resource_type: metatool_resource_type, name: "Resource Test One", abbreviation: "test1") }
  let(:tool_group_first) { ToolGroup.first }
  let(:tool_group_last) { ToolGroup.last }
  let(:invalid_id) { 999999 }

  before(:each) do
    %i[one two three].each do |name|
      FactoryBot.create(:tool_group, name: name)
    end
    FactoryBot.create(:rule_language, tool_group: ToolGroup.first, languages: languages)
    FactoryBot.create(:rule_country, tool_group: ToolGroup.first, countries: countries)
    FactoryBot.create(:rule_praxis, tool_group: ToolGroup.first, openness: openness, confidence: confidence)
    resource
  end

  after(:each) do
    RuleCountry.delete_all
    RuleLanguage.delete_all
    RulePraxis.delete_all
    ResourceToolGroup.delete_all
    ToolGroup.delete_all
  end

  post "tool-groups" do
    let(:attrs) do
      {
        name: "test",
        suggestions_weight: "1.0"
      }
    end

    let(:attrs_invalid) do
      {
        name: "test",
        suggestions_weight: ""
      }
    end

    requires_authorization

    it "create tool group" do
      do_request data: {type: "tool-group", attributes: attrs}
      expect(status).to eq(201)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
    end

    it "returns error message when tool group is not created" do
      do_request data: {type: "tool-group", attributes: attrs_invalid}

      puts response_body.inspect
      expect(status).to eq(422)
      expect(JSON.parse(response_body)).to eq("errors" => [{"source"=>{"details"=>"Validation failed: Suggestions weight can't be blank", "pointer"=>"/data/attributes/suggestions_weight"}}])
    end
  end

  post "tool-groups/:tool_group_id/tools" do
    let(:attributes) do
      {
        "suggestions-weight": "1.0"
      }
    end

    let(:relationships) {
      {
        tool: {
          data: {
            type: "resource",
            id: Resource.first.id
          }
        }
      }
    }

    requires_authorization

    it "create tool group tool succeeds" do
      do_request tool_group_id: tool_group_first.id, data: {
        type: "tool-group-tool", attributes: attributes, relationships: relationships
      }
      expect(status).to eq(201)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
    end

    it "create tool group tool fails" do
      do_request tool_group_id: invalid_id, data: {
        type: "tool-group-tool", attributes: attributes, relationships: relationships
      }

      expect(status).to eq(422)
      expect(JSON.parse(response_body)).to eq("errors" => [{"source"=>{"details"=>"Validation failed: Tool group must exist", "pointer"=>"/data/attributes/tool_group"}}])
    end
  end

  put "tool-groups/:tool_group_id/tools/:id" do
    requires_authorization

    let(:tool_group_id) { ToolGroup.first.id }
    let(:suggestions_weight) { 0.5 }
    let(:relationship) { ResourceToolGroup.create!(resource_id: resource.id, tool_group_id: tool_group_id, suggestions_weight: 1) }
    let(:attrs) do
      {
        "suggestions-weight": suggestions_weight
      }
    end

    it "update tool group tool" do
      do_request id: relationship.id, tool_group_id: tool_group_id, data: {
        type: "tool-group-tool",
        attributes: {
          "suggestions-weight": suggestions_weight
        },
        relationships: {
          tool: {
            data: {
              type: "resource",
              id: resource.id
            }
          }
        }
      }

      expect(status).to eq(202)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
      expect(JSON.parse(response_body)["data"]["attributes"]["suggestions-weight"]).to eql suggestions_weight
    end
  end

  delete "tool-groups/:tool_group_id/tools/:id" do
    let(:tool_group_id) { ToolGroup.first.id }
    let(:relationship) { ResourceToolGroup.create!(resource_id: resource.id, tool_group_id: tool_group_id, suggestions_weight: 1) }
    requires_authorization

    it "delete tool_group tool succeed and returns ':not_content'" do
      do_request id: relationship.id, tool_group_id: tool_group_id

      expect(status).to be(204)
    end

    it "delete tool_group tool fails and returns ':not_found'" do
      do_request id: invalid_id, tool_group_id: tool_group_id

      expect(status).to be(404)
    end
  end

  get "tool-groups" do
    requires_authorization

    let(:include_all_rules) { "rules-language,rules-praxis,rules-country" }
    let(:include_only_rules_language) { "rules-language" }
    let(:include_only_rules_country) { "rules-country" }
    let(:include_only_rules_praxis) { "rules-praxis" }

    context "including all rules related and all fields" do
      it "list groups" do
        do_request include: include_all_rules

        included = JSON.parse(response_body)["included"]
        expect(status).to eq(200)
        expect(JSON.parse(response_body)["data"].count).to eql 3
        expect(included.count).to eql 3

        expect(included[0]["attributes"]["languages"]).to eql languages
        expect(included[1]["attributes"]["countries"]).to eql countries

        expect(included[2]["attributes"]["openness"]).to eql openness
        expect(included[2]["attributes"]["confidence"]).to eql confidence
      end
    end

    context "including for praxis only field openness" do
      it "list groups" do
        do_request include: include_only_rules_praxis, "fields[tool-group-rule-praxis]": "openness"
        expect(status).to eq(200)

        included = JSON.parse(response_body)["included"]
        expect(included[0]["attributes"].key?("openness")).to eql true
        expect(included[0]["attributes"].key?("confidence")).to eql false
      end
    end

    context "including for praxis only field confidence" do
      it "list groups" do
        do_request include: include_only_rules_praxis, "fields[tool-group-rule-praxis]": "confidence"

        expect(status).to eq(200)

        included = JSON.parse(response_body)["included"]
        expect(included[0]["attributes"].key?("openness")).to eql false
        expect(included[0]["attributes"].key?("confidence")).to eql true
      end
    end

    context "including only rules language" do
      it "list groups" do
        do_request include: include_only_rules_language
        expect(status).to eq(200)

        included = JSON.parse(response_body)["included"]
        expect(included[0]["attributes"]["languages"]).to eql languages
        expect(return_rules_included?(included, "type", "tool-group-rule-country")).to eql nil
        expect(return_rules_included?(included, "type", "tool-group-rule-praxis")).to eql nil
      end
    end

    context "including only rules country" do
      it "list groups" do
        do_request include: include_only_rules_country
        expect(status).to eq(200)

        included = JSON.parse(response_body)["included"]
        expect(included[0]["attributes"]["countries"]).to eql countries
        expect(return_rules_included?(included, "type", "tool-group-rule-language")).to eql nil
        expect(return_rules_included?(included, "type", "tool-group-rule-praxis")).to eql nil
      end
    end

    context "including only rules praxis" do
      it "list groups" do
        do_request include: include_only_rules_praxis
        expect(status).to eq(200)

        included = JSON.parse(response_body)["included"]
        expect(included[0]["attributes"]["openness"]).to eql openness
        expect(included[0]["attributes"]["confidence"]).to eql confidence
        expect(return_rules_included?(included, "type", "tool-group-rule-language")).to eql nil
        expect(return_rules_included?(included, "type", "tool-group-rule-country")).to eql nil
      end
    end
  end

  get "tool-groups/:id" do
    requires_authorization
    let(:id) { ToolGroup.first.id }
    let(:include_all_rules) { "rules-language,rules-praxis,rules-country" }
    let(:include_only_rules_language) { "rules-language" }
    let(:include_only_rules_country) { "rules-country" }
    let(:include_only_rules_praxis) { "rules-praxis" }

    context "including all rules related" do
      it "get tool_group by id" do
        do_request id: id, include: include_all_rules
        expect(status).to eq(200)

        included = JSON.parse(response_body)["included"]
        expect(JSON.parse(response_body)["data"]["attributes"]["name"]).to eql "one"
        expect(included[0]["attributes"]["languages"]).to eql languages
        expect(included[1]["attributes"]["countries"]).to eql countries
        expect(included[2]["attributes"]["openness"]).to eql openness
        expect(included[2]["attributes"]["confidence"]).to eql confidence
      end
    end

    context "including only rules language" do
      it "get tool_group by id" do
        do_request id: id, include: include_only_rules_language
        expect(status).to eq(200)

        included = JSON.parse(response_body)["included"]
        expect(included[0]["attributes"]["languages"]).to eql languages
        expect(return_rules_included?(included, "type", "tool-group-rule-country")).to eql nil
        expect(return_rules_included?(included, "type", "tool-group-rule-praxis")).to eql nil
      end
    end

    context "including only rules country" do
      it "get tool_group by id" do
        do_request id: id, include: include_only_rules_country
        expect(status).to eq(200)

        included = JSON.parse(response_body)["included"]
        expect(included[0]["attributes"]["countries"]).to eql countries
        expect(return_rules_included?(included, "type", "tool-group-rule-language")).to eql nil
        expect(return_rules_included?(included, "type", "tool-group-rule-praxis")).to eql nil
      end
    end

    context "including only rules praxis" do
      it "get tool_group by id" do
        do_request id: id, include: include_only_rules_praxis
        expect(status).to eq(200)

        included = JSON.parse(response_body)["included"]
        expect(included[0]["attributes"]["openness"]).to eql openness
        expect(included[0]["attributes"]["confidence"]).to eql confidence
        expect(return_rules_included?(included, "type", "tool-group-rule-language")).to eql nil
        expect(return_rules_included?(included, "type", "tool-group-rule-country")).to eql nil
      end
    end
  end

  put "tool-groups/:id" do
    requires_authorization
    let(:id) { ToolGroup.first.id }
    let(:attrs) do
      {
        name: "new name"
      }
    end

    it "update tool group" do
      do_request data: {type: "tool-group", attributes: attrs}

      expect(status).to be(202)
      expect(JSON.parse(response_body)["data"]["attributes"]["name"]).to eql "new name"
    end
  end

  delete "tool-groups/:id" do
    let(:id) { ToolGroup.first.id }

    requires_authorization

    it "delete tool_group succeed and returns ':no_content'" do
      do_request

      expect(status).to be(204)
    end

    it "delete tool_group fails and returns ':not_found'" do
      do_request id: invalid_id

      expect(status).to be(404)
    end
  end

  private

  def return_rules_included?(json_array, key_to_find, value_to_find)
    value_to_find if json_array.any? { |json_element| json_element[key_to_find] == value_to_find }
  end
end
