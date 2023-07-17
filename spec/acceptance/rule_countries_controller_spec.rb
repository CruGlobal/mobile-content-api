# frozen_string_literal: true

require "acceptance_helper"

resource "RuleCountries" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  before(:each) do
    %i[one].each do |name|
      FactoryBot.create(:tool_group, name: name)
    end
    FactoryBot.create(:rule_country, tool_group: ToolGroup.first)
  end

  after(:each) do
    RuleCountry.delete_all
    ToolGroup.delete_all
  end

  post "tool-groups/:id/rule-countries" do
    requires_authorization

    let(:valid_attrs) do
      {
        countries: ["CA", "FR", "US"],
        tool_group_id: ToolGroup.first.id,
        negative_rule: "true"
      }
    end

    let(:invalid_attrs) do
      {
        countries: ["1A"],
        tool_group_id: ToolGroup.first.id,
        negative_rule: "true"
      }
    end

    context "with valid countries values" do
      it "creates a rule country" do
        do_request data: {type: "tool-group-rule-countries", attributes: valid_attrs}

        expect(status).to eq(201)
        expect(JSON.parse(response_body)["data"]).not_to be_nil
      end
    end

    context "with invalid countries values" do
      it "returns an error" do
        do_request data: {type: "tool-group-rule-countries", attributes: invalid_attrs}

        expect(status).to eq(422)
        expect(JSON.parse(response_body)["data"]).to be_nil
        expect(JSON.parse(response_body)["error"]["countries"][0]).to eql "must contain only ISO-3166 alpha-2 country codes"
      end
    end
  end

  patch "tool-groups/:tool_group_id/rule-countries/:id" do
    requires_authorization

    let(:tool_group_id) { ToolGroup.first.id }
    let(:id) { RuleCountry.first.id }
    let(:countries) { ["FR", "AR"] }

    let(:attrs) do
      {
        countries: countries,
        negative_rule: false
      }
    end

    it "update rule country" do
      do_request data: {type: "tool-group-rule-countries", attributes: attrs}
      
      expect(status).to be(202)
      expect(JSON.parse(response_body)["data"]["attributes"]["countries"]).to eql countries
      expect(JSON.parse(response_body)["data"]["attributes"]["negative-rule"]).to eql false
    end
  end

  delete "tool-groups/:tool_group_id/rule-countries/:id" do
    requires_authorization

    let(:tool_group_id) { ToolGroup.first.id }
    let(:id) { RuleCountry.first.id }

    it "delete rule country" do
      do_request
      expect(status).to be(204)
    end
  end
end
