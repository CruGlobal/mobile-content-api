# frozen_string_literal: true

require "acceptance_helper"

resource "RulePraxes" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  before(:each) do
    %i[one].each do |name|
      FactoryBot.create(:tool_group, name: name)
    end
    FactoryBot.create(:rule_praxis, tool_group: ToolGroup.first)
  end

  after(:each) do
    RulePraxis.delete_all
    ToolGroup.delete_all
  end

  post "tool-groups/:id/rules-praxis" do
    requires_authorization
    let(:tool_group_id) { ToolGroup.first.id }
    let(:openness) { [1, 2] }
    let(:confidence) { [4, 5] }

    let(:valid_attrs) do
      {
        openness: openness,
        confidence: confidence,
        negative_rule: "true"
      }
    end

    let(:repeated_attrs) do
      {
        openness: openness,
        confidence: confidence,
        negative_rule: "true"
      }
    end

    let(:empty_attrs) do
      {
        openness: [],
        confidence: [],
        negative_rule: "true"
      }
    end

    let(:non_valid_openness_attr) do
      {
        openness: [0],
        confidence: [1, 2],
        negative_rule: "true"
      }
    end

    let(:non_valid_confidence_attr) do
      {
        openness: [1, 2, 3, 4, 5],
        confidence: [6],
        negative_rule: "true"
      }
    end

    context "with valid openness and confidence values" do
      it "create rule praxis" do
        do_request tool_group_id: tool_group_id, data: {type: "tool-group-rules-praxis", attributes: valid_attrs}

        expect(status).to eq(201)
        expect(JSON.parse(response_body)["data"]).not_to be_nil
      end
    end

    context "with repeated openness and confidence values" do
      before do
        FactoryBot.create(:rule_praxis, tool_group_id: tool_group_id, openness: openness, confidence: confidence)
      end

      it "returns an error" do
        do_request tool_group_id: tool_group_id, data: {type: "tool-group-rules-praxis", attributes: repeated_attrs}

        expect(status).to eq(422)
        expect(JSON.parse(response_body)["data"]).to be_nil
        expect(JSON.parse(response_body)["errors"][0]["detail"]).to eql "Validation failed: Tool group combination already exists"
      end
    end

    context "with empty or null openness and confidence values" do
      it "returns an error" do
        do_request tool_group_id: tool_group_id, data: {type: "tool-group-rules-praxis", attributes: empty_attrs}

        expect(status).to eq(422)
        expect(JSON.parse(response_body)["data"]).to be_nil
        expect(JSON.parse(response_body)["errors"][0]["detail"]).to eql "Validation failed: Either 'openness' or 'confidence' must be present"
      end
    end

    context "with non valid openness values" do
      it "returns an error" do
        do_request tool_group_id: tool_group_id, data: {type: "tool-group-rules-praxis", attributes: non_valid_openness_attr}

        expect(status).to eq(422)
        expect(JSON.parse(response_body)["data"]).to be_nil
        expect(JSON.parse(response_body)["errors"][0]["detail"]).to eql "Validation failed: Openness must contain integer values between 1 and 5 or an empty array"
      end
    end

    context "with non valid confidence values" do
      it "returns an error" do
        do_request tool_group_id: tool_group_id, data: {type: "tool-group-rules-praxis", attributes: non_valid_confidence_attr}

        expect(status).to eq(422)
        expect(JSON.parse(response_body)["data"]).to be_nil
        expect(JSON.parse(response_body)["errors"][0]["detail"]).to eql "Validation failed: Confidence must contain integer values between 1 and 5 or an empty array"
      end
    end
  end

  patch "tool-groups/:tool_group_id/rules-praxis/:id" do
    requires_authorization

    let(:tool_group_id) { ToolGroup.first.id }
    let(:id) { RulePraxis.first.id }
    let(:openness) { [1, 2] }
    let(:confidence) { [3, 4] }

    let(:attrs) do
      {
        openness: openness,
        confidence: confidence,
        negative_rule: false
      }
    end

    it "update rule praxis" do
      do_request data: {type: "tool-group-rules-praxis", attributes: attrs}

      expect(status).to be(202)
      expect(JSON.parse(response_body)["data"]["attributes"]["openness"]).to eql openness
      expect(JSON.parse(response_body)["data"]["attributes"]["confidence"]).to eql confidence
      expect(JSON.parse(response_body)["data"]["attributes"]["negative-rule"]).to eql false
    end
  end

  delete "tool-groups/:tool_group_id/rules-praxis/:id" do
    requires_authorization

    let(:tool_group_id) { ToolGroup.first.id }
    let(:id) { RulePraxis.first.id }

    it "delete rule praxis" do
      do_request
      expect(status).to be(204)
    end
  end
end
