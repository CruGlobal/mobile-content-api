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

    let(:attrs) do
      {
        countries: ["CA", "FR", "US"],
        tool_group_id: ToolGroup.first.id,
        negative_rule: "true"
      }
    end

    it "create rule country" do
      do_request data: {type: "tool-group-rule-countries", attributes: attrs}
      
      expect(status).to eq(201)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
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