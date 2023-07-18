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

  before(:each) do
    %i[one two three].each do |name|
      FactoryBot.create(:tool_group, name: name)
    end
    FactoryBot.create(:rule_language, tool_group: ToolGroup.first, languages: languages)
    FactoryBot.create(:rule_country, tool_group: ToolGroup.first, countries: countries)
    FactoryBot.create(:rule_praxi, tool_group: ToolGroup.first, openness: openness, confidence: confidence)
  end

  after(:each) do
    RuleCountry.delete_all
    RuleLanguage.delete_all
    RulePraxi.delete_all
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

      expect(status).to eq(400)
      expect(JSON.parse(response_body)["errors"]).not_to be_empty
      expect(JSON.parse(response_body)["errors"][0]["detail"]).to eql "Validation failed: Suggestions weight can't be blank"
    end
  end

  get "tool-groups" do
    requires_authorization

    it "list groups" do
      do_request
      expect(status).to eq(200)
      expect(JSON.parse(response_body)["data"].count).to eql 3
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

        expect(JSON.parse(response_body)["data"]["attributes"]["name"]).to eql "one"
        expect(JSON.parse(response_body)["included"][0]["attributes"]["languages"]).to eql languages
        expect(JSON.parse(response_body)["included"][1]["attributes"]["countries"]).to eql countries
        expect(JSON.parse(response_body)["included"][2]["attributes"]["openness"]).to eql openness
        expect(JSON.parse(response_body)["included"][2]["attributes"]["confidence"]).to eql confidence
      end
    end

    context "including only rules language" do
      it "get tool_group by id" do
        do_request id: id, include: include_only_rules_language
        expect(status).to eq(200)

        expect(JSON.parse(response_body)["included"][0]["attributes"]["languages"]).to eql languages
        expect(find_value_by_key(JSON.parse(response_body)["included"], "type", "tool-group-rule-country")).to eql nil
        expect(find_value_by_key(JSON.parse(response_body)["included"], "type", "tool-group-rule-praxis")).to eql nil
      end
    end

    context "including only rules country" do
      it "get tool_group by id" do
        do_request id: id, include: include_only_rules_country
        expect(status).to eq(200)

        expect(JSON.parse(response_body)["included"][0]["attributes"]["countries"]).to eql countries
        expect(find_value_by_key(JSON.parse(response_body)["included"], "type", "tool-group-rule-language")).to eql nil
        expect(find_value_by_key(JSON.parse(response_body)["included"], "type", "tool-group-rule-praxis")).to eql nil
      end
    end

    context "including only rules praxis" do
      it "get tool_group by id" do
        do_request id: id, include: include_only_rules_praxis
        expect(status).to eq(200)

        expect(JSON.parse(response_body)["included"][0]["attributes"]["openness"]).to eql openness
        expect(JSON.parse(response_body)["included"][0]["attributes"]["confidence"]).to eql confidence
        expect(find_value_by_key(JSON.parse(response_body)["included"], "type", "tool-group-rule-language")).to eql nil
        expect(find_value_by_key(JSON.parse(response_body)["included"], "type", "tool-group-rule-country")).to eql nil
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

    it "delete tool_group" do
      do_request

      expect(status).to be(204)
    end
  end

  private

  def find_value_by_key(json_array, key_to_find, value_to_find)
    value_to_find if json_array.any? { |json_element| json_element[key_to_find] == value_to_find }
  end
end
