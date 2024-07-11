# frozen_string_literal: true

require "acceptance_helper"

resource "UserTrainingTips" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let!(:user) { FactoryBot.create(:user) }
  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }

  post "users/me/training-tips" do
    let(:attributes) do
      {
        "tip-id": "tip id here",
        "is-completed": true
      }
    end

    let(:attributes_invalid) do
      {
        "tip-id": ""
      }
    end

    let(:relationships) {
      {
        language: {
          data: {
            type: "language",
            id: Language.first.id
          }
        },

        tool: {
          data: {
            type: "resource",
            id: Resource.first.id
          }
        }
      }
    }

    requires_okta_login

    it "create user training tip" do
      do_request data: {type: "training-tip", attributes: attributes, relationships: relationships}

      expect(status).to eq(201)
      data = JSON.parse(response_body)["data"]
      expect(data).not_to be_nil
      expect(data["attributes"]).to eq(serializer_output_style(attributes))
      expect(data["relationships"]).to eq(serializer_output_style(relationships))
    end

    it "returns error message when user training tip is not created" do
      do_request data: {type: "training-tips", attributes: attributes_invalid, relationships: relationships}

      expect(status).to eq(422)
      expect(JSON.parse(response_body)["errors"]).not_to be_empty
      expect(JSON.parse(response_body)["errors"][0]["detail"]).to eql "Validation failed: Tip can't be blank"
    end
  end

  put "users/me/training-tips/:id" do
    requires_okta_login

    let(:tool) { Resource.first }
    let(:language) { Language.first }
    let(:training_tip) { FactoryBot.create(:user_training_tip, user_id: user.id, tool_id: tool.id, language_id: language.id, tip_id: "tip", is_completed: false) }
    let(:id) { training_tip.id }

    let(:attributes) do
      {
        "tip-id": "new tip id",
        "is-completed": true
      }
    end

    let(:relationships) do
      {
        language: {
          data: {
            type: "language",
            id: Language.second.id
          }
        },

        tool: {
          data: {
            type: "resource",
            id: Resource.second.id
          }
        }
      }
    end

    it "updates a user training tip" do
      do_request id: training_tip.id, data: {
        type: "training-tip",
        attributes: attributes,
        relationships: relationships
      }

      expect(status).to eq(200)
      data = JSON.parse(response_body)["data"]
      expect(data).not_to be_nil
      expect(data["attributes"]).to eq(serializer_output_style(attributes))
      expect(data["relationships"]).to eq(serializer_output_style(relationships))
    end
  end

  delete "users/me/training-tips/:id" do
    requires_okta_login

    let(:resource) { Resource.first }
    let(:tool) { Resource.first }
    let(:language) { Language.first }
    let!(:training_tip) { FactoryBot.create(:user_training_tip, user_id: user.id, tool_id: tool.id, language_id: language.id, tip_id: "tip", is_completed: false) }
    let(:id) { training_tip.id }
    let(:invalid_id) { -1 }
    requires_authorization

    it "delete user training tip succeed and returns ':not_content'" do
      expect do
        do_request id: id
      end.to change(UserTrainingTip, :count).by(-1)

      expect(status).to be(204)
      expect(UserTrainingTip.find_by(id: id)).to be_nil
    end

    it "delete user training tip fails and returns ':not_found'" do
      do_request id: invalid_id

      expect(status).to be(404)
    end
  end

  get "users/me?include=training-tips" do
    requires_authorization

    let(:tool) { Resource.first }
    let(:language) { Language.first }
    let!(:training_tip_1) { FactoryBot.create(:user_training_tip, user_id: user.id, tool_id: tool.id, language_id: language.id, tip_id: "tip", is_completed: false) }

    let(:tool_2) { Resource.second }
    let(:language_2) { Language.second }
    let!(:training_tip_2) { FactoryBot.create(:user_training_tip, user_id: user.id, tool_id: tool_2.id, language_id: language_2.id, tip_id: "tip", is_completed: false) }

    # this should not be included
    let(:other_user) { FactoryBot.create(:user) }
    let(:tool_3) { Resource.first }
    let(:language_3) { Language.first }
    let!(:training_tip_3) { FactoryBot.create(:user_training_tip, user_id: other_user.id, tool_id: tool_3.id, language_id: language_3.id, tip_id: "tip", is_completed: false) }

    it "gets all training tips for a user" do
      do_request
      expect(status).to eq(200)

      data = JSON.parse(response_body)["data"]
      expect(data["relationships"]["training-tips"]["data"]).to eq([{"id" => training_tip_1.id.to_s, "type" => "training-tip"}, {"id" => training_tip_2.id.to_s, "type" => "training-tip"}])

      included = JSON.parse(response_body)["included"]
      expect(included.first["id"]).to eq(training_tip_1.id.to_s)
      expect(included.second["id"]).to eq(training_tip_2.id.to_s)
    end
  end

  # change _ to - in keys, and make any ids (number values) strings
  def serializer_output_style(hash)
    hash.deep_transform_keys { |key| key.to_s.tr("_", "-") }.deep_transform_values { |v| /^\d+$/.match?(v.to_s) ? v.to_s : v }
  end
end
