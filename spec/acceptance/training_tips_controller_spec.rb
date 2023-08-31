# frozen_string_literal: true

require "acceptance_helper"

resource "TrainingTips" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  let(:tip) { FactoryBot.create(:tip) }
  let(:user) { FactoryBot.create(:user) }

  post "training-tips" do
    requires_authorization
    let(:attributes) do
      {
        tool: "kgp",
        locale: "en",
        "tip-id": tip.id,
        "is-completed": true,
        user_id: user.id
      }
    end

    it "create training tip" do
      do_request data: {type: "training-tip", attributes: attributes}
      expect(status).to eq(201)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
    end

    xit "returns error message when tool group is not created" do
      do_request data: {type: "tool-group", attributes: attrs_invalid}

      expect(status).to eq(400)
      expect(JSON.parse(response_body)["errors"]).not_to be_empty
      expect(JSON.parse(response_body)["errors"][0]["detail"]).to eql "Validation failed: Suggestions weight can't be blank"
    end
  end
end
