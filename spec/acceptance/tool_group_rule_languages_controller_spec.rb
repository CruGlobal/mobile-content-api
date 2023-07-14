# frozen_string_literal: true

require "acceptance_helper"

resource "ToolGroupsRuleLanguages" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  before(:each) do
    %i[one].each do |name|
      FactoryBot.create(:tool_group, name: name)
    end
  end

  after(:each) do
    ToolGroupRuleLanguage.delete_all
    ToolGroup.delete_all
  end

  post "tool-groups/:tool_group_id/rule-languages" do
    let(:attrs) do
      {
        languages: ["en", "es"],
        tool_group_id: ToolGroup.first.id,
        negative_rule: "true"
      }
    end

    requires_authorization

    it "create tool group" do
      do_request data: {type: "tool-group-rule-languages", attributes: attrs}
      expect(status).to eq(201)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
    end
  end
end
