# frozen_string_literal: true

require "acceptance_helper"

resource "CustomTips" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:structure) { FactoryBot.attributes_for(:custom_tip)[:structure] }
  let(:tip) { FactoryBot.create(:tip) }

  let(:authorization) { AuthToken.generic_token }

  post "custom_tips/" do
    requires_authorization

    context "creating" do
      let(:attrs) { {language_id: 3, tip_id: tip.id, structure: structure} }

      it "create a custom tip" do
        do_request data: {type: type, attributes: attrs}

        expect(status).to be(201)
        expect(JSON.parse(response_body)["data"]).not_to be_nil
      end

      it "creating sets location header", document: false do
        do_request data: {type: type, attributes: attrs}

        expect(response_headers["Location"]).to match(%r{custom_tips/\d+})
      end
    end

    it "update a custom tip" do
      existing_custom_tip = FactoryBot.create(:custom_tip, tip: tip)
      attributes = existing_custom_tip.attributes.with_indifferent_access.slice(:language_id, :tip_id, :structure)

      do_request data: {type: type, attributes: attributes}

      expect(status).to be(200)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
    end
  end

  delete "custom_tips/:id" do
    let(:custom_tip) { FactoryBot.create(:custom_tip, tip: tip) }
    let(:id) { custom_tip.id }

    requires_authorization

    it "delete a custom tip" do
      do_request

      expect(status).to be(204)
      expect(response_body).to be_empty
    end
  end
end
