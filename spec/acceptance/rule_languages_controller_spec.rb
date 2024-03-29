# frozen_string_literal: true

require "acceptance_helper"

resource "RuleLanguages" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  before(:each) do
    %i[one].each do |name|
      FactoryBot.create(:tool_group, name: name)
    end
    FactoryBot.create(:rule_language, tool_group: ToolGroup.first)
  end

  after(:each) do
    RuleLanguage.delete_all
    ToolGroup.delete_all
  end

  post "tool-groups/:id/rules-language" do
    requires_authorization

    let(:tool_group_id) { ToolGroup.first.id }

    let(:attrs) do
      {
        languages: ["en", "es"],
        negative_rule: "true"
      }
    end

    it "create rule language succeed" do
      do_request tool_group_id: tool_group_id, data: {type: "tool-group-rules-language", attributes: attrs}
      expect(status).to eq(201)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
    end

    it "create rule language fails" do
      do_request tool_group_id: 99999999, data: {type: "tool-group-rules-language", attributes: attrs}

      expect(status).to eq(404)
      expect(JSON.parse(response_body)).to eql({"errors" => [{"source" => {"pointer" => "/data/attributes/id"}, "detail" => "Couldn't find ToolGroup with 'id'=99999999"}]})
    end
  end

  patch "tool-groups/:tool_group_id/rules-language/:id" do
    requires_authorization

    let(:tool_group_id) { ToolGroup.first.id }
    let(:id) { RuleLanguage.first.id }
    let(:languages) { ["fr", "es", "pt"] }

    let(:attrs) do
      {
        languages: languages,
        negative_rule: false
      }
    end

    it "update rule language" do
      do_request data: {type: "tool-group-rules-language", attributes: attrs}

      expect(status).to be(202)
      expect(JSON.parse(response_body)["data"]["attributes"]["languages"]).to eql languages
      expect(JSON.parse(response_body)["data"]["attributes"]["negative-rule"]).to eql false
    end
  end

  delete "tool-groups/:tool_group_id/rules-language/:id" do
    requires_authorization

    let(:tool_group_id) { ToolGroup.first.id }
    let(:id) { RuleLanguage.first.id }

    it "delete rule language" do
      do_request
      expect(status).to be(204)
    end
  end
end
