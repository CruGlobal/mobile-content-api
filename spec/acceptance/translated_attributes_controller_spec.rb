# frozen_string_literal: true

require "acceptance_helper"

resource "TranslatedAttributes" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.generic_token }
  let(:resource_id) { Resource.first.id }
  let(:attrs) { {key: "key", onesky_phrase_id: "phrase", required: true} }

  post "/resources/:resource_id/translated_attributes" do
    let(:id) { 100 }

    requires_authorization

    it "create a TranslatedAttribute" do
      expect do
        do_request data: {type: type, attributes: attrs}
      end.to change { TranslatedAttribute.count }.by(1)

      expect(status).to be(204)
      expect(response_body).to be_empty
      expect(TranslatedAttribute.last.attributes.symbolize_keys.slice(:key, :onesky_phrase_id, :required, :resource_id)).to eq(attrs.merge(resource_id: resource_id))
      expect(response_headers["Location"]).to eq("/resources/#{resource_id}/translated_attributes/#{TranslatedAttribute.last.id}")
    end
  end

  context "existing translated_attribute" do
    let(:translated_attribute) { FactoryBot.create(:translated_attribute, attrs.merge(resource_id: resource_id)) }
    let!(:id) { translated_attribute.id }

    put "/resources/:resource_id/translated_attributes/:id" do
      let(:new_attrs) { {key: "updated key", onesky_phrase_id: "phrase", required: true} }

      requires_authorization

      it "update a Translated Attribute" do
        do_request data: {type: type, attributes: new_attrs}

        expect(status).to be(204)
        expect(response_body).to be_empty
        expect(translated_attribute.reload.attributes.symbolize_keys.slice(:key, :onesky_phrase_id, :required, :resource_id)).to eq(new_attrs.merge(resource_id: resource_id))
      end
    end

    delete "/resources/:resource_id/translated_attributes/:id" do
      requires_authorization

      it "delete a Translated Attribute" do
        expect do
          do_request
        end.to change { TranslatedAttribute.count }.by(-1)

        expect(status).to be(204)
        expect(response_body).to be_empty
        expect(TranslatedAttribute.find_by(id: id)).to be nil
      end
    end
  end
end
