# frozen_string_literal: true

require "acceptance_helper"

resource "RulePraxis" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  before(:each) do
    %i[one].each do |name|
      FactoryBot.create(:tool_group, name: name)
    end
    FactoryBot.create(:rule_praxi, tool_group: ToolGroup.first)
  end

  after(:each) do
    RulePraxi.delete_all
    ToolGroup.delete_all
  end

  post "tool-groups/:id/rule-praxis" do
    requires_authorization

    let(:attrs) do
      {
        tool_group_id: ToolGroup.first.id,
        openness: [123, 456],
        confidence: [8, 9],
        negative_rule: "true"
      }
    end

    it "create rule praxis" do
      do_request data: {type: "tool-group-rule-praxis", attributes: attrs}
      
      expect(status).to eq(201)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
    end
  end
end