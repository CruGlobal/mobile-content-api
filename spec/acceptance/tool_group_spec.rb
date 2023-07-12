# frozen_string_literal: true

require "acceptance_helper"

resource "ToolGroups" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  before(:each) do
    %i[one two three].each do |name|
      FactoryBot.create(:tool_group, name: name)
    end
  end

  after(:each) do
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
        suggestions_weight: nil
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
      expect(status).to eq(422)
      expect(JSON.parse(response_body)["error"]).not_to be_empty
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

    it "get tool_group by id" do
      do_request
      expect(status).to eq(200)
      expect(JSON.parse(response_body)["data"]["attributes"]["name"]).to eql "one"
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
end
